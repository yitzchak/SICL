(cl:in-package #:sicl-new-boot-phase-2)

(eval-when (:compile-toplevel) (sb:enable-parcl-symbols client))

(defun boot (boot)
  (format *trace-output* "**************** Phase 2~%")
  (let* ((client (make-instance 'client))
         (environment (create-environment client))
         (global-environment
           (trucler:global-environment client environment))
         (env:*client* client)
         (env:*environment* global-environment))
    (setf (sb:e2 boot) global-environment)
    (reinitialize-instance client
      :environment global-environment)
    ;; We saved the SICL class named T under the name sb::sicl-t.  Now
    ;; we need to put it back as class T in E1, because it is going to
    ;; be used as a specializer in bridge generic functions.
    (setf (clo:find-class client (sb:e1 boot) 't)
          (clo:find-class client (sb:e1 boot) 'sb::sicl-t))
    (clo:make-variable
     client global-environment '*package* (find-package '#:common-lisp-user))
    (sb:define-package-functions client global-environment)
    (sb:define-backquote-macros client global-environment)
    (import-from-host client global-environment)
    (sb:import-khazern client global-environment)
    (sb:define-environment-functions client global-environment)
    (clo:make-variable client global-environment
                       @sicl-environment:*environment*
                       global-environment)
    (clo:make-variable client global-environment
                       @sicl-environment:*client*
                       client)
    (define-ensure-method-combination-template
        client (sb:e1 boot) global-environment)
    (define-^ensure-method-combination
        client (sb:e1 boot) global-environment)
    (define-find-method-combination-template client global-environment)
    (setf (clo:fdefinition
           client global-environment
           @sicl-clos:^ensure-generic-function-using-class)
          (clo:fdefinition
           client (sb:e1 boot)
           @sicl-clos:ensure-generic-function-using-class))
    (setf (clo:fdefinition
           client global-environment @sicl-clos:^ensure-class-using-class)
          (clo:fdefinition
           client (sb:e1 boot) @sicl-clos:ensure-class-using-class))
    (setf (clo:fdefinition
           client global-environment
           @sicl-clos:^ensure-method-using-generic-function)
          (clo:fdefinition
           client (sb:e1 boot)
           @sicl-clos:ensure-method-using-generic-function))
    (setf (clo:fdefinition
           client global-environment @sicl-clos:^method-function)
          (clo:fdefinition
           client (sb:e1 boot) @clostrophilia:method-function))
    (sb:ensure-asdf-system client environment "sicl-clos-ensure-metaobject")
    (define-ecclesia-functions client (sb:e1 boot) global-environment)
    (sb:ensure-asdf-system
     client environment "clostrophilia-method-combination")
    ;; VALIDATE-SUPERCLASS is going to be called with the class T as
    ;; one of the arguments, but in phase 1 we replace the target
    ;; class T by the host class T so that unspecialized methods, or
    ;; methods specialized to T use the host class T.  So
    ;; VALIDATE-SUPERCLASS is not functional as it is in E1.  Sice we
    ;; do not expect to load code for which VALIDATE-SUPERCLASS
    ;; returns NIL, we make it always return T.
    (setf (clo:fdefinition
           client (sb:e1 boot) @clostrophilia:validate-superclass)
          (constantly t))
    ;; This might be a mistake.  The thing is that the code for adding
    ;; reader and writer methods loaded into E1 calls
    ;; ENSURE-GENERIC-FUNCTION, but the generic function it needs to
    ;; ensure is in E2.  And ENSURE-GENERIC-FUNCTION in E1 has been
    ;; set in phase 1 to call ERROR.  The easy way to fix this is to
    ;; replace ENSURE-GENERIC-FUNCTION in E1 by the new one now in E2.
    ;; But I am not very happy about modifying E1 in phase 2.  A
    ;; better solution would be for the code that adds readers and
    ;; writers to call (say) _ENSURE-GENERIC-FUNCTION, and to define
    ;; that function in E1 to be the ENSURE-GENERIC-FUNCTION of E2.
    ;; But that code is in Clostrophilia, and it is not ideal to have
    ;; Clostrophilia code reflect the SICL bootstrapping procedure. 
    (setf (clo:fdefinition client (sb:e1 boot) 'ensure-generic-function)
          (clo:fdefinition
           client global-environment 'ensure-generic-function))
    (setf (clo:fdefinition
           client (sb:e1 boot) @clostrophilia:find-class-t)
          (lambda ()
            (clo:find-class client global-environment 't)))
    (setf (clo:fdefinition
           client global-environment @sicl-clos:^make-instance)
          (clo:fdefinition client (sb:e1 boot) 'make-instance))
    ;; ADD-DIRECT-METHOD is called by ADD-METHOD, but it doesn't make
    ;; sense to add a SICL method to a host class.
    (setf (clo:fdefinition
           client (sb:e1 boot) @clostrophilia:add-direct-method)
          (constantly nil))
    (sb:ensure-asdf-system
     client environment "clostrophilia-class-hierarchy")
    (sb:ensure-asdf-system
     client environment "sicl-asdf-packages")
    (setf (clo:macro-function
           client global-environment @asdf-user:defsystem)
          (constantly nil))
    (setf (clo:macro-function
           client global-environment @asdf:defsystem)
          (constantly nil))
    (sb:ensure-asdf-system
     client environment "predicament-base" :load-system-file t)
    ;; The system predicament base contains the definition of the
    ;; variable PREDICAMENT-ASDF:*STRING-DESIGNATORS*, so when we
    ;; loaded that system into E2, that variable got defined in E2.
    ;; However, we now want to load a a package definition into E2
    ;; that uses the value of that variable at read time.  But read
    ;; time is done by Eclector in the host envronment, and that
    ;; variable is not defined in the host environment.  So we do that
    ;; with the following code.
    (let* ((symbol @predicament-asdf:*string-designators*)
           (value (clo:symbol-value client global-environment symbol)))
      (eval `(defparameter ,symbol ',value)))
    (sb:ensure-asdf-system
     client environment "predicament-packages-intrinsic")
    (setf (clo:fdefinition
           client (sb:e1 boot)
           @clostrophilia:find-class-standard-object)
          (constantly (clo:find-class
                       client global-environment 'standard-object)))
    (clo:make-variable
     client (sb:e1 boot) @clostrophilia:*standard-object*
     (clo:find-class client global-environment 'standard-object))
    (clo:make-variable
     client (sb:e1 boot) @clostrophilia:*funcallable-standard-object*
     (clo:find-class
      client global-environment @clostrophilia:funcallable-standard-object))
    (let* ((name @clostrophilia:find-method-combination)
           (function (clo:fdefinition client global-environment name)))
      (clo:make-variable client (sb:e1 boot)
                         @sicl-clos:*standard-method-combination*
                         (funcall function client 'standard '())))
    (setf (clo:fdefinition
           client global-environment @sicl-clos:^allocate-instance-using-class)
          (clo:fdefinition
           client (sb:e1 boot) @clostrophilia:allocate-instance-using-class))
    (sb:ensure-asdf-system
     client environment "sicl-new-boot-phase-2-additional-classes")
    (define-class-of-and-stamp client (sb:e1 boot) global-environment)
    (setf (clo:fdefinition client (sb:e1 boot) @clostrophilia:class-of+1)
          (clo:fdefinition client global-environment 'class-of))
    (setf (clo:fdefinition client (sb:e1 boot) @clostrophilia:stamp+1)
          (clo:fdefinition client global-environment @clostrophilia:stamp))
    (sb:ensure-asdf-system client environment "sicl-clos-make-instance")
    (load-predicament client environment global-environment)
    (clo:make-variable client (sb:e1 boot)
                       @predicament:*condition-maker* 'make-condition)
    (let ((symbol @clostrophilia:standard-instance-access))
      (setf (clo:fdefinition client global-environment symbol)
            #'sb:standard-instance-access)
      (setf (clo:fdefinition client global-environment `(setf ,symbol))
            #'(setf sb:standard-instance-access)))
    (sb:ensure-asdf-system
     client environment "clostrophilia-instance-structure")
    (sb:ensure-asdf-system
     client environment "clostrophilia-standard-object-initialization")
    (let ((symbol-class (clo:find-class client global-environment 'symbol))
          (finalize-inheritance
            (clo:fdefinition
             client (sb:e1 boot) @clostrophilia:finalize-inheritance)))
      (funcall finalize-inheritance symbol-class))
    (setf (clo:fdefinition
           client global-environment @clostrophilia:shared-initialize-aux-1)
          (clo:fdefinition
           client (sb:e1 boot) @clostrophilia:shared-initialize-aux))
    ;; ctype uses ASSERT and ASSERT expands to RESTART-CASE which
    ;; contains a TYPECASE which expands to TYPEP, but we don't have
    ;; TYPEP since the very purpose of ctype is to define TYPEP.  But
    ;; assertions should not fail at this point in the process anyway.
    (setf (clo:macro-function client global-environment 'assert)
          (lambda (form environment)
            ;; We might put some trace output here.
            (declare (ignore form environment))
            nil))
    ;; It might be a mistake to define TYPEXPAND this way.
    (setf (clo:fdefinition
           client global-environment @sicl-type:typexpand)
          (lambda (type-specifier &optional environment)
            (declare (ignore environment))
            (values type-specifier nil)))
    (setf (clo:fdefinition
           client global-environment @sicl-clos:intern-eql-specializer-1)
          (clo:fdefinition
           client (sb:e1 boot) @sicl-clos:intern-eql-specializer))
    (load-ctype client environment global-environment)
    ;; The ctype library defines SUBCLASSP to call
    ;; SICL-CLOS:CLASS-PRECEDENCE-LIST with the subclass as an
    ;; argument.  But in E2, the arguments to SUBCLASSP are bridge
    ;; objects, so they need to be accessed using host generic
    ;; functions locaed in E1.  So we redefine SUBCLASSP here.
    (setf (clo:fdefinition client global-environment @ctype:subclassp)
          (lambda (sub super)
            (let ((class-precedence-list
                    (clo:fdefinition
                     client (sb:e1 boot) @sicl-clos:class-precedence-list)))
              (member super (funcall class-precedence-list sub))))))
  boot)
