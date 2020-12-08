(cl:in-package #:sicl-boot-phase-5)

(defun finalize-classes (e4 e5)
  (format *trace-output* "Finalizing all classes in ~a..." (sicl-boot:name e5))
  (finish-output *trace-output*)
  (let ((visited (make-hash-table :test #'eq))
        (finalized-p (env:fdefinition (env:client e4) e4 'sicl-clos::class-finalized-p))
        (finalize (env:fdefinition (env:client e4) e4 'sicl-clos:finalize-inheritance)))
    (do-all-symbols (symbol)
      (unless (gethash symbol visited)
        (setf (gethash symbol visited) t)
        (let ((class (env:find-class (env:client e5) e5 symbol)))
          (unless (or (null class) (funcall finalized-p class))
            (funcall finalize class))))))
  (format *trace-output* "done~%")
  (finish-output *trace-output*))

(defun satiate-generic-functions (e4 e5)
  (let ((processed (make-hash-table :test #'eq))
        (client (env:client e5))
        (satiation-function
          (env:fdefinition (env:client e4) e4 'sicl-clos::satiate-generic-function))
        (generic-function-class
          (env:find-class (env:client e4) e4 'standard-generic-function)))
    (do-all-symbols (symbol)
      (unless (gethash symbol processed)
        (setf (gethash symbol processed) t)
        (when (and (env:fboundp client e5 symbol)
                   (not (env:special-operator client e5 symbol))
                   (null (env:macro-function client e5 symbol)))
          (let ((fun (env:fdefinition client e5 symbol)))
            (when (and (typep fun 'sicl-boot::header)
                       (eq (slot-value fun 'sicl-boot::%class)
                           generic-function-class))
              (funcall satiation-function fun))))
        (when (env:fboundp client e5 `(setf ,symbol))
          (let ((fun (env:fdefinition client e5 `(setf ,symbol))))
            (when (and (typep fun 'sicl-boot::header)
                       (eq (slot-value fun 'sicl-boot::%class)
                           generic-function-class))
              (funcall satiation-function fun))))))))

(defun prepare-next-phase (e3 e4 e5)
  (load-source-file "CLOS/class-of-defun.lisp" e5)
  (enable-typep e5)
  (enable-object-creation e4 e5)
  (setf (env:fdefinition (env:client e5) e5 'compile)
        (lambda (x lambda-expression)
          (assert (null x))
          (assert (and (consp lambda-expression) (eq (first lambda-expression) 'lambda)))
          (let* ((cst (cst:cst-from-expression lambda-expression))
                 (ast (cleavir-cst-to-ast:cst-to-ast (env:client e5) cst e5)))
            (with-intercepted-function-cells
                (e5
                 (make-instance
                  (env:function-cell (env:client e3) e3 'make-instance))
                 (sicl-clos:method-function
                  (env:function-cell (env:client e4) e4 'sicl-clos:method-function)))
              (funcall (env:fdefinition (env:client e5) e5 'sicl-boot:ast-eval)
                       ast)))))
  (enable-array-access e5)
  (enable-method-combinations e4 e5)
  (enable-compute-discriminating-function e4 e5)
  (enable-generic-function-creation e5)
  ;; (enable-printing e5)
  (finalize-classes e4 e5)
  (define-error-functions '(sicl-clos::all-descendants sicl-clos::cartesian-product) e4)
  (load-source-file "CLOS/satiation.lisp" e4))

