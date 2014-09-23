(cl:in-package #:cleavir-walker)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Generic function WALK-FORM.  
;;;
;;; This generic function is the main entry point for the code walker.

(defgeneric walk-form (form walker environment))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Generic function WALK-SEQUENCE.  
;;;
;;; This generic function is called by the code walker in order to
;;; process a sequences of forms such as the forms of a body that is
;;; treated as a PROGN.

(defgeneric walk-sequence (sequence walker environment))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Generic function WALK-SELF-EVALUATING.  
;;;
;;; This generic function is called by the code walker in order to
;;; process a self-evaluating object.

(defgeneric walk-self-evaluating (form walker environment))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Generic function WALK-SYMBOL.  
;;;
;;; This generic function is called by the code walker in order to
;;; process a symbol.

(defgeneric walk-symbol (form walker environment))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Generic function WALK-COMPOUND.  
;;;
;;; This generic function is called by the code walker in order to
;;; process a compound form.

(defgeneric walk-compound (form walker environment))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Default method on WALK-SEQUENCE.

(defmethod walk-sequence (sequence walker env)
  (loop for form in sequence
	collect (walk-form form walker sequence)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Default method on WALK-FORM.

(defmethod walk-form (form walker env)
  (cond ((and (not (consp form)) (not (symbolp form)))
	 (walk-self-evaluating form walker env))
	((symbolp form)
	 (walk-symbol form walker env))
	(t
	 (walk-compound form walker env))))
