(cl:in-package #:sicl-new-boot)

(defun import-khazern (client global-environment)
  (setf (clo:macro-function client global-environment 'loop)
        (macro-function 'khazern-extrinsic:loop))
  (setf (clo:macro-function client global-environment 'loop-finish)
        (macro-function 'khazern-extrinsic:loop-finish)))
