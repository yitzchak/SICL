(cl:in-package #:sicl-boot-phase-6)

(defun enable-object-allocation (e5)
  (setf (env:fdefinition (env:client e5) e5 'sicl-clos::allocate-general-instance)
        (lambda (class size)
          (make-instance 'sicl-boot:header
            :class class
            :rack (make-array size :initial-element 10000000))))
  (load-source-file "CLOS/stamp-offset-defconstant.lisp" e5)
  (load-source-file "CLOS/effective-slot-definition-class-support.lisp" e5)
  (load-source-file "CLOS/effective-slot-definition-class-defgeneric.lisp" e5)
  (load-source-file "CLOS/effective-slot-definition-class-defmethods.lisp" e5)
  (load-source-file "CLOS/allocate-instance-support.lisp" e5)
  (load-source-file "CLOS/allocate-instance-defgenerics.lisp" e5)
  (load-source-file "CLOS/allocate-instance-defmethods.lisp" e5))

(defun enable-object-initialization (e5)
  (setf (env:constant-variable (env:client e5) e5 'sicl-clos::+unbound-slot-value+)
        10000000)
  (load-source-file "CLOS/slot-bound-using-index.lisp" e5)
  (load-source-file "CLOS/standard-instance-access.lisp" e5))

(defun enable-object-creation (e5)
  (enable-object-allocation e5)
  (enable-object-initialization e5))