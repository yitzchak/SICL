(cl:in-package #:sicl-standard-environment-functions)

;;;; Macro expansion.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Method on CLEAVIR-ENV:MACRO-FUNCTION.
;;;
;;; If we want to use the augmentation environments provided by
;;; Cleavir, we must supply a method on this generic function,
;;; specialized to our global environment.
;;;
;;; In this case, the method simply calls the generic function that is
;;; part of our environment protocol.

(defmethod cleavir-env:macro-function (symbol (env environment))
  (macro-function symbol env))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Function MACROEXPAND.
;;;
;;; The HyperSpec says that this function repeatedly calls
;;; MACROEXPAND-1 until the second return value is false, so that is
;;; what we do too.
;;;
;;; However, that is not what the compiler should do.  The reason is
;;; that MACROEXPAND-1 might very well return another macro form that
;;; in addition has a compiler macro associated with it.  In that
;;; case, it would be inappropriate (though technically not "wrong")
;;; for the compiler to call MACROEXPAND-1 again.  Instead, it should
;;; apply the compiler macro first and then expand again.  In fact,
;;; the application of the compiler macro function might return
;;; something other than a macro form. It could also be the case that
;;; what MACROEXPAND-1 returns is NOT a macro form, but it is a
;;; function-call form with a compiler macro associated with it, and
;;; the compiler macro might return a macro form.
;;;
;;; For reasons mentioned in the previous paragraph, the compiler does
;;; not call macroexpand at all, but instead a function called
;;; FULLY-EXPAND-FORM defined below.

(defun macroexpand (form &optional environment)
  (multiple-value-bind (expansion expanded-p)
      (macroexpand-1 form environment)
    (if expanded-p
	(loop while (multiple-value-bind (new-expansion expanded-p)
			(macroexpand-1 expansion environment)
		      (setf expansion new-expansion)
		      expanded-p)
	      finally (return (values expansion t)))
	(values form nil))))

