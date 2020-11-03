(cl:in-package #:sicl-boot-phase-3)

(defun prepare-next-phase (e2 e3 e4)
  (setf (env:fdefinition (env:client e4) e4 'sicl-boot:ast-eval)
        (lambda (ast)
          (let ((code (sicl-ast-evaluator:translate-top-level-ast ast)))
            (funcall (compile nil code) e4))))
  (sicl-boot:copy-macro-functions e3 e4)
  (enable-method-combinations e2 e3 e4)
  (setf (env:special-operator (env:client e4) e4 'cleavir-primop:multiple-value-call) t)
  (enable-compute-discriminating-function e3)
  (setf (env:fdefinition (env:client e4) e4 'find-method-combination)
        (lambda (name arguments)
          (funcall (env:fdefinition (env:client e3) e3 'sicl-method-combination:find-method-combination)
                   name arguments)))
  (setf (env:macro-function (env:client e4) e4 'sicl-clos:find-method-combination)
        (lambda (form environment)
          (declare (ignore environment))
          `(find-method-combination ,(third form) ,(fourth form))))
  (load-source-file "CLOS/defgeneric-support.lisp" e4)
  (import-functions-from-host
   '(cleavir-code-utilities:parse-generic-function-lambda-list
     cleavir-code-utilities:required)
   e3)
  (setf (env:fdefinition (env:client e3) e3 'sicl-clos:set-funcallable-instance-function)
        #'closer-mop:set-funcallable-instance-function)
  (load-source-file "CLOS/invalidate-discriminating-function.lisp" e3)
  (setf (env:fdefinition (env:client e3) e3 'slot-value)
        (lambda (object slot-name)
          (error "SLOT-VALUE called with ~s and ~s" object slot-name)))
  (setf (env:fdefinition (env:client e3) e3 '(setf slot-value))
        (lambda (value object slot-name)
          (error "(SETF SLOT-VALUE) called with ~s, ~s and ~s" value object slot-name)))
  (import-functions-from-host
   '(shared-initialize initialize-instance)
   e3)
  (load-source-file "CLOS/generic-function-initialization-support.lisp" e3)
  (with-intercepted-function-cells
      (e3
       (sicl-clos:method-function
        (list (lambda (method)
                (closer-mop:method-function method)))))
    (load-source-file "CLOS/generic-function-initialization-defmethods.lisp" e3))
  (enable-defgeneric e2 e4)
  (enable-defmethod e3 e4)
  (enable-defclass e2 e3 e4))
