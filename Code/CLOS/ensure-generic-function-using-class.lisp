(cl:in-package #:sicl-clos)

;;; For the specification of this generic function, see
;;; http://metamodular.com/CLOS-MOP/ensure-generic-function-using-class.html
;;;
;;; We handle an additional keyword argument compared to the
;;; specification, namely ENVIRONMENT.  It can be used to specify in
;;; which the generic function is to be found or defined.  It defaults
;;; to the environment in which this function was loaded.
(defgeneric ensure-generic-function-using-class
    (generic-function
     function-name
     &key
       argument-precedence-order
       declarations
       documentation
       generic-function-class
       lambda-list
       method-class
       method-combination
       name
       class-environment
       function-environment
     &allow-other-keys))

(defun canonicalize-generic-function-class
    (generic-function-class environment)
  (cond ((symbolp generic-function-class)
         (find-class generic-function-class t environment))
        ((member (find-class 'generic-function)
                 (class-precedence-list generic-function-class))
         generic-function-class)
        (t
         (error 'generic-function-class-must-be-class-or-name
                :object generic-function-class))))

(defun canonicalize-method-class (method-class environment)
  (cond ((symbolp method-class)
         (find-class method-class t environment))
        ((member (find-class 'method) (class-precedence-list method-class))
         method-class)
        (t
         (error "method class must be a class or a name"))))

(defun canonicalize-keyword-arguments (keyword-arguments)
  (let ((result (copy-list keyword-arguments)))
    (loop while (remf result :generic-function-class))
    (loop while (remf result :environment))
    result))

(defmethod ensure-generic-function-using-class
    ((generic-function null)
     function-name
     &rest
       all-keyword-arguments
     &key
       (class-environment sicl-environment:*environment*)
       (function-environment sicl-environment:*environment*)
       (generic-function-class
        (find-class 'standard-generic-function t class-environment))
       (method-class nil method-class-p)
       (method-combination nil method-combination-p)
     &allow-other-keys)
  (declare (ignore generic-function))
  (setf generic-function-class
        (canonicalize-generic-function-class
         generic-function-class class-environment))
  (when method-class-p
    (setf method-class
          (canonicalize-method-class method-class class-environment)))
  (unless method-combination-p
    ;; Neither the Common Lisp standard nor the AMOP indicates where
    ;; this keyword argument is defaulted, but it has to be here,
    ;; because, this is where we find out that there is no generic
    ;; function with the name given as an argument.
    (unless (class-finalized-p generic-function-class)
      (finalize-inheritance generic-function-class))
    (let ((proto (class-prototype generic-function-class)))
      (setf method-combination
            (find-method-combination proto 'standard '()))))
  (let* ((remaining-keys
           (canonicalize-keyword-arguments all-keyword-arguments))
         (result
           (if method-class-p
               (apply #'make-instance generic-function-class
                      ;; The AMOP does
                      :name function-name
                      :method-class method-class
                      :method-combination method-combination
                      remaining-keys)
               (apply #'make-instance generic-function-class
                      :name function-name
                      :method-combination method-combination
                      remaining-keys))))
    (setf (sicl-environment:fdefinition
           sicl-environment:*client* function-environment function-name)
          result)))

(defmethod ensure-generic-function-using-class
    ((generic-function generic-function)
     function-name
     &rest
       all-keyword-arguments
     &key
       (class-environment sicl-environment:*environment*)
       function-environment
       (generic-function-class
        (find-class 'standard-generic-function t class-environment))
       (method-class nil method-class-p)
     &allow-other-keys)
  (declare (ignore function-name function-environment))
  (setf generic-function-class
        (canonicalize-generic-function-class
         generic-function-class class-environment))
  (unless (eq generic-function-class (class-of generic-function))
    (error "classes don't agree ~s and ~s of ~s"
           generic-function-class (class-of generic-function) generic-function))
  (when method-class-p
    (setf method-class
          (canonicalize-method-class method-class class-environment)))
  (let ((remaining-keys
          (canonicalize-keyword-arguments all-keyword-arguments)))
    (if method-class-p
        (apply #'reinitialize-instance generic-function
               :method-class method-class
               remaining-keys)
        (apply #'reinitialize-instance generic-function
               remaining-keys)))
  generic-function)