(cl:in-package #:asdf-user)

(defsystem :sicl-conditions
  :serial t
  :components
  ((:file "packages")
   (:file "report-mixin-defclass")
   (:file "support")
   (:file "debugger-hook-defparameter")
   (:file "condition-defclass")
   (:file "debugger")
   (:file "define-condition-defmacro")
   (:file "condition-hierarchy")
   (:file "with-store-value-restart-defmacro")
   (:file "check-type-defmacro")
   (:file "restarts-utilities")
   (:file "restarts")
   (:file "handlers-utilities")
   (:file "handlers")
   (:file "make-condition-defgeneric")
   (:file "make-condition-defmethods")
   (:file "signaling")))
