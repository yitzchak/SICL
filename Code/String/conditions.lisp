;;;; Copyright (c) 2014, 2015
;;;;
;;;;     Robert Strandh (robert.strandh@gmail.com)
;;;;
;;;; all rights reserved. 
;;;;
;;;; Permission is hereby granted to use this software for any 
;;;; purpose, including using, modifying, and redistributing it.
;;;;
;;;; The software is provided "as-is" with no warranty.  The user of
;;;; this software assumes any responsibility of the consequences. 

;;;; This file is part of the string module of the SICL project.
;;;; See the file SICL.text for a description of the project. 
;;;; See the file string.text for a description of the module.

(cl:in-package #:sicl-string)

(define-condition bag-is-dotted-list
    (type-error acclimation:condition)
  ()
  (:report (lambda (condition stream)
             (format stream
                     "If a character bag is a list,~@
                      it must be a proper list.~@
                      But the following dotted list was found instead:~@
                      ~s."
                     (type-error-datum condition)))))

(define-condition bag-is-circular-list
    (type-error acclimation:condition)
  ()
  (:report (lambda (condition stream)
             (format stream
                     "If a character bag is a list,~@
                      it must be a proper list.~@
                      But the following circular list was found instead:~@
                      ~s."
                     (type-error-datum condition)))))

(define-condition bag-contains-non-character
    (type-error acclimation:condition)
  ()
  (:report (lambda (condition stream)
             (format stream
                     "A character bag must be a sequence~@
                      that contains only characters.~@
                      But the following element was found~@
                      which is not a character:~@
                      ~s."
                     (type-error-datum condition)))))

(define-condition invalid-bounding-indices
    (error acclimation:condition)
  ((%target :initarg :target :reader target)
   (%start :initarg start :reader start)
   (%end :initarg end :reader end)))
