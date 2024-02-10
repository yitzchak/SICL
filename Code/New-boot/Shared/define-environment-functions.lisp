(cl:in-package #:sicl-new-boot)

(defun define-environment-functions (client global-environment)
  (flet ((import-function (name function)
           (setf (clo:fdefinition client global-environment name)
                 function)))
    (import-function 'fboundp #'env:fboundp)
    (import-function 'fdefinition #'env:fdefinition)
    (import-function '(setf fdefinition) #'(setf env:fdefinition))
    (import-function 'find-class #'env:find-class)
    (import-function '(setf find-class) #'(setf env:find-class))
    (import-function 'macro-function #'env:macro-function)
    (import-function '(setf macro-function) #'(setf env:macro-function))
    (import-function 'compiler-macro-function #'env:compiler-macro-function)
    (import-function '(setf compiler-macro-function)
                     #'(setf env:compiler-macro-function))
    (import-function 'boundp #'env:boundp)
    (import-function 'symbol-value #'env:symbol-value)
    (import-function '(setf symbol-value) #'(setf env:symbol-value))
    (let ((symbol-define-constant
            (intern-parcl-symbol
             client "SICL-ENVIRONMENT" "DEFINE-CONSTANT")))
      (import-function symbol-define-constant #'env:define-constant)
      (setf (clo:macro-function client global-environment 'defconstant)
            (lambda (form environment)
              (declare (ignore environment))
              (destructuring-bind (name value-form &optional documentation)
                  (rest form)
                (declare (ignore documentation))
                `(,symbol-define-constant ',name ,value-form)))))))
