(cl:in-package #:sicl-evaluation-and-compilation)

(define-condition environment-must-be-omitted-or-nil
    (error acclimation:condition)
  ((%environment :initarg :environment :reader environment)))

(define-condition load-time-value-read-only-p-not-evaluated
    (style-warning)
  ((%code :initarg :code :reader code))
  (:report (lambda (condition stream)
             (format stream
                     "The second (optional) argument (read-only-p)~@
                      is not evaluated, so a boolean value (T or NIL)~@
                      was expected. But the following was found instead:~@
                      ~s"
                     (code condition)))))
