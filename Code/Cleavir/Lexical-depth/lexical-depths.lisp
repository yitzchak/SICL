(cl:in-package #:cleavir-lexical-depth)

;;;; An instruction A is a DESCENDANT of an instruction B if and only
;;;; if it is possible to reach A by starting at B and following
;;;; SUCCESSOR references.  As defined here, the set of DESCENDANTS of
;;;; an instruction includes the instruction itself.
;;;;
;;;; Recall that an ENTER-INSTRUCTION is the successor or no other
;;;; instruction.
;;;;
;;;; The OWNER of an instruction A is the outermost ENTER-INSTRUCTION
;;;; of all the ENTER-INSTRUCTIONs of which A is a descendant.  The
;;;; owner of a datum D is the outermost ENTER-INSTRUCTION of all the
;;;; owners of all the instructions using D.
;;;;
;;;; Each ENTER-INSTRUCTION A defines a PROCEDURE which is a the set
;;;; of all the instructions owned by A.  We extend the definition of
;;;; ownership so that a procedure P is the owner of some instruction
;;;; or datum X if an only if the unique ENTER-INSTRUCTION of P is the
;;;; owner of X. 
;;;;
;;;; A procedure P is a LEXICAL PARENT of a procedure Q if and only if
;;;; either some instruction in P is the direct successor of some
;;;; instruction in Q, or some instruction A in Q refers to a datum
;;;; owned by P. 
;;;;
;;;; The LEXICAL DEPTH of a procedure P is defined recursively as
;;;; follows:
;;;; 
;;;;   * If P has no lexical parent then its lexical depth is 0.
;;;;
;;;;   * Otherwise, the lexical depth of P is d+1, where d is the
;;;      maximum depth of any of its lexical parents. 

(defun data (instruction)
  (append (cleavir-mir:inputs instruction)
	  (cleavir-mir:outputs instruction)))

(defvar *ownerships*)

(defun owner (item)
  (gethash item *ownerships*))

(defun (setf owner) (new-owner item)
  (setf (gethash item *ownerships*) new-owner))

;;; Compute the owner of each instruction and each datum.  The return
;;; value is an EQ hash table mapping an instruction or a datum to its
;;; owner.
(defun compute-ownerships (enter-instruction)
  (let ((worklist (list enter-instruction))
	(*ownerships* (make-hash-table :test #'eq)))
    (flet
	((process-function (enter-instruction)
	   (labels
	       ((traverse (instruction)
		  (when  (null (owner instruction))
		    (setf (owner instruction) enter-instruction)
		    (loop for datum in (data instruction)
			  do (when (null (owner datum))
			       (setf (owner datum) enter-instruction)))
		    (when (typep instruction 'cleavir-mir:enclose-instruction)
		      (let ((code (cleavir-mir:code instruction)))
			(setf worklist (append worklist (list code)))))
		    (mapc #'traverse (cleavir-mir:successors instruction)))))
	     (traverse enter-instruction))))
      (loop until (null worklist)
	    do (process-function (pop worklist))))
    *ownerships*))

(defvar *lexical-depths*)

(defun lexical-depth (enter-instruction)
  (gethash enter-instruction *lexical-depths*))

(defun (setf lexical-depth) (new-depth enter-instruction)
  (setf (gethash enter-instruction *lexical-depths*) new-depth))

;;; Return the lexical depth of each instruction and each datum of the
;;; program.  The return value is an EQ hash table mapping each item
;;; (instruction or datum) to its lexical depth.
(defun lexical-depths (enter-instruction)
  (let ((*ownerships* (compute-ownerships enter-instruction))
	(worklist (list enter-instruction))
	(*lexical-depths* (make-hash-table :test #'eq)))
    (flet
	((process-function (enter-instruction)
	   (setf (lexical-depth enter-instruction) 0)
	   (let ((visited (make-hash-table :test #'eq)))
	     (labels
		 ((traverse (instruction)
		    (unless (gethash instruction visited)
		      (setf (gethash instruction visited) t)
		      (when (typep instruction 'cleavir-mir:enclose-instruction)
			(let ((code (cleavir-mir:code instruction)))
			  (setf worklist (append worklist (list code)))))
		      (loop with i-owner = (owner instruction)
			    for datum in (data instruction)
			    for d-owner = (owner datum)
			    do (unless (eq d-owner i-owner)
				 (setf (lexical-depth enter-instruction)
				       (max (lexical-depth enter-instruction)
					    (1+ (lexical-depth d-owner))))))
		      (loop with i-owner = (owner instruction)
			    for successor in (cleavir-mir:successors instruction)
			    for s-owner = (owner successor)
			    do (if (eq i-owner s-owner)
				   (traverse successor)
				   (setf (lexical-depth enter-instruction)
					 (max (lexical-depth enter-instruction)
					      (1+ (lexical-depth s-owner)))))))))
	       (traverse enter-instruction)))))
      (loop until (null worklist)
	    do (process-function (pop worklist))))
    ;; Add remaining instructions and data to table.
    (maphash (lambda (item owner)
	       (when (null (gethash item *lexical-depths*))
		 (setf (gethash item *lexical-depths*)
		       (gethash owner *lexical-depths*))))
	     *ownerships*)
    *lexical-depths*))

(defun distinguish-lexical-variables (enter-instruction lexical-depths)
  (let ((*lexical-depths* lexical-depths)
	(visited (make-hash-table :test #'eq)))
    ;; First find all lexical locations that should be turned
    ;; into captured lexical locations.
    (labels ((traverse (instruction)
	       (unless (gethash instruction visited)
		 (setf (gethash instruction visited) t)
		 (loop with type = 'cleavir-mir:lexical-location
		       for datum in (data instruction)
		       do (when (and (typep datum type)
				     (/= (lexical-depth datum)
					 (lexical-depth instruction)))
			    (change-class datum 'cleavir-mir:captured-location)))
		 (loop for succ in (cleavir-mir:successors instruction)
		       do (traverse succ))
		 (when (typep instruction 'cleavir-mir:enclose-instruction)
		   (traverse (cleavir-mir:code instruction))))))
      (traverse enter-instruction))
    ;; Next find all lexical locations that were not converted in the
    ;; first step, and convert them to simple lexical locations.  It
    ;; is enough to check the outputs of each instruction because each
    ;; lexical location must be the output of at least one
    ;; instruction.
    (clrhash visited)
    (labels ((traverse (instruction)
	       (unless (gethash instruction visited)
		 (setf (gethash instruction visited) t)
		 (loop with type = '(and cleavir-mir:lexical-location
				         (not cleavir-mir:captured-location))
		       for datum in (cleavir-mir:outputs instruction)
		       do (when (typep datum type)
			    (change-class datum 'cleavir-mir:simple-location)))
		 (loop for succ in (cleavir-mir:successors instruction)
		       do (traverse succ))
		 (when (typep instruction 'cleavir-mir:enclose-instruction)
		   (traverse (cleavir-mir:code instruction))))))
      (traverse enter-instruction))))
    
    
