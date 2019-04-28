; DivideScannedImages.scm
; by Francois Malan
; Based on a script originally by Rob Antonishen http://ffaat.pointclark.net
;
; Locates each separate element in an image and creates a new image from each.
; if option is selected, will call the deskew plugin by Karl Chen https://github.com/prokoudine/gimp-deskew-plugin (if it is installed) on each item
;
; License:
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. 
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; The GNU Public License is available at
; http://www.gnu.org/copyleft/gpl.html

(define (script_fu_DivideScannedImages img inLayer inSquareCrop inPadding inLimit inDeskew inAutoClose inThreshold inSize inDefBg inBgCol inCorner inX inY inSaveInSourceDir inDir inSaveType inJpgQual inFileName inFileNumber)
  (let*
    (
      (inSaveFiles TRUE)
      (width (car (gimp-image-width img)))
      (height (car (gimp-image-height img)))
      (newpath 0)
      (strokes 0)
      (tempVector 0)
      (tempImage 0)
      (tempLayer 0)
      (bounds 0)
      (centroidx 0)
      (centroidy 0)
      (sizex 0)
      (sizey 0)
      (halfsidelength 0)
      (sidelength 0)
      (count 0)
      (numextracted 0)
      (saveString "")
      (newFileName "")
      (tempdisplay 0)
      (buffname "dsibuff")
      (pathchar (if (equal? (substring gimp-dir 0 1) "/") "/" "\\"))
      (imgpath "")
    )
    ;  it begins here
    (gimp-context-push)
    (set! imgpath (car (gimp-image-get-filename img)))
    (gimp-image-undo-disable img)
    
    ;logging
    ;(gimp-message-set-handler ERROR-CONSOLE)
    ;(gimp-message-set-handler CONSOLE)
    ;(gimp-message-set-handler MESSAGE-BOX)
    ;or start GIMP wwith "gimp --console-messages" to spawn a console box
    ;then use this:
    ;(gimp-message "foobar") 
    
    ;testing for functions defined
    ;(if (defined? 'plug-in-shift) (gimp-message "It Exists") (gimp-message "Doesnt Exist"))
    
    ;set up saving
    (if (= inSaveFiles TRUE)
      (set! saveString
      (cond 
        (( equal? inSaveType 0 ) ".jpg" )
        (( equal? inSaveType 1 ) ".png" )
        (( equal? inSaveType 2) (string-append "." (car(reverse(strbreakup (car (gimp-image-get-name img)) ".")))))
      )
    ))
    ; The block below was included in the original "DivideScannedImages.scm", but seems to cause problems by adding a white border which is then subsequently sampled.
    ; Expand the image a bit to fix problem with images near the right edge. Probably could get away just expanding
    ; width but go ahead and expand height in case same issue is there...
    ;(set! width (+ width 30))
    ;(set! height (+ height 30))
    ;(gimp-image-resize img width height 15 15)
    ;(gimp-layer-resize-to-image-size inLayer)
        
    ; If the background wasn't manually defined, pick the colour from one of the four corners (using radius 3 average)
    (if (not (= inDefBg TRUE))
    (begin
      (cond   ; else
      ( (equal? inCorner 0)
        (set! inBgCol (car (gimp-image-pick-color img inLayer inX inY TRUE TRUE 5)))
      )
      ( (equal? inCorner 1)
        (set! inBgCol (car (gimp-image-pick-color img inLayer (- width inX) inY TRUE TRUE 5)))
      )
      ( (equal? inCorner 2)
        (set! inBgCol (car (gimp-image-pick-color img inLayer inX (- height inY) TRUE TRUE 5))) 
      )
      ( (equal? inCorner 3)
        (set! inBgCol (car (gimp-image-pick-color img inLayer (- width inX) (- height inY) TRUE TRUE 5)))
      ))
    ))
    (gimp-image-select-color img CHANNEL-OP-REPLACE inLayer inBgCol)
    (gimp-context-set-background inBgCol)
  
    ; convert inverted copy of the background selection to a path
    (gimp-selection-feather img (/ (min width height) 100))
    (gimp-selection-sharpen img)
    (gimp-selection-invert img)
    (plug-in-sel2path RUN-NONINTERACTIVE img inLayer)
    
    ;break up the vectors and loop across each vector (boundary path of each object)
    (set! newpath (vector-ref (cadr (gimp-image-get-vectors img)) 0)) 
   
    (set! strokes (gimp-vectors-get-strokes newpath))
    (while (and (< count (car strokes)) (< numextracted inLimit))
    
      (set! tempVector (gimp-vectors-new img "Temp"))
      (gimp-image-add-vectors img (car tempVector) -1)
      (gimp-vectors-stroke-new-from-points (car tempVector)
        (list-ref (gimp-vectors-stroke-get-points newpath (vector-ref (cadr strokes) count)) 0)
        (list-ref (gimp-vectors-stroke-get-points newpath (vector-ref (cadr strokes) count)) 1)
        (list-ref (gimp-vectors-stroke-get-points newpath (vector-ref (cadr strokes) count)) 2)
        (list-ref (gimp-vectors-stroke-get-points newpath (vector-ref (cadr strokes) count)) 3)
      )
      (gimp-vectors-to-selection (car tempVector) CHANNEL-OP-REPLACE TRUE FALSE 0 0)
      
      ;check for minimum size
      (set! bounds (gimp-selection-bounds img))
      (set! sizex (- (list-ref bounds 3) (list-ref bounds 1)))
      (set! sizey (- (list-ref bounds 4) (list-ref bounds 2)))
      (if (and (> sizex inSize) (> sizey inSize) ;min size slider
               (< sizex width) (< sizey height)) ;max size image
        (begin
        (if (and (= inDeskew TRUE) (defined? 'gimp-deskew-plugin))
          (begin
          (gimp-progress-set-text "Deskewing...")
          (gimp-rect-select img (list-ref bounds 1) (list-ref bounds 2)
                                sizex sizey CHANNEL-OP-REPLACE FALSE 0 )
          (set! buffname (car (gimp-edit-named-copy inLayer buffname)))
          (set! tempImage (car (gimp-edit-named-paste-as-new buffname)))
          (set! tempLayer (car (gimp-image-get-active-layer tempImage))) 
          (gimp-image-undo-disable tempImage)
          ;(set! tempdisplay (car (gimp-display-new tempImage)))
          (gimp-layer-flatten tempLayer)
          (gimp-deskew-plugin 0 tempImage tempLayer 0 0 0 0 0)
          (gimp-image-resize-to-layers tempImage)
          (gimp-layer-flatten tempLayer)
          (gimp-fuzzy-select tempLayer 0 0 inThreshold CHANNEL-OP-REPLACE TRUE FALSE 0 TRUE) 
          (gimp-selection-invert tempImage)
          (set! bounds (gimp-selection-bounds tempImage))
          (set! sizex (- (list-ref bounds 3) (list-ref bounds 1)))
          (set! sizey (- (list-ref bounds 4) (list-ref bounds 2)))
          (gimp-selection-none tempImage)
          (gimp-image-crop tempImage sizex sizey (list-ref bounds 1) (list-ref bounds 2))
          (if (= inSquareCrop TRUE)
          (begin
            (if (> sizex sizey)
              (begin
                (script-fu-addborder tempImage tempLayer 0 (/ (- sizex sizey) 2) inBgCol 0)
                (gimp-image-raise-item-to-top tempImage tempLayer)
                (gimp-image-merge-visible-layers tempImage EXPAND-AS-NECESSARY)
                (set! tempLayer (car (gimp-image-get-active-layer tempImage)))
             ))
            (if (< sizex sizey)
              (begin
                (script-fu-addborder tempImage tempLayer (/ (- sizey sizex) 2) 0 inBgCol 0)
                (gimp-image-raise-item-to-top tempImage tempLayer)
                (gimp-image-merge-visible-layers tempImage EXPAND-AS-NECESSARY)
                (set! tempLayer (car (gimp-image-get-active-layer tempImage)))
             ))
          )))
          (begin
          (set! tempImage img)
          (set! tempLayer (car (gimp-image-get-active-layer tempImage))) 
          (gimp-image-undo-disable tempImage)
          (if (= inSquareCrop TRUE)
            (begin
            (set! centroidx (* 0.5 (+ (list-ref bounds 1) (list-ref bounds 3))))
            (set! centroidy (* 0.5 (+ (list-ref bounds 2) (list-ref bounds 4))))
            (set! halfsidelength (+ inPadding (* 0.5 (max sizex sizey))))
            (gimp-rect-select tempImage (- centroidx halfsidelength) (- centroidy halfsidelength)
                                  (* halfsidelength 2) (* halfsidelength 2)
                                  CHANNEL-OP-REPLACE FALSE 0 )
            )
            (gimp-rect-select tempImage (list-ref bounds 1) (list-ref bounds 2)
                                    sizex sizey CHANNEL-OP-REPLACE FALSE 0)
          )
          (set! buffname (car (gimp-edit-named-copy inLayer buffname)))
          (set! tempImage (car (gimp-edit-named-paste-as-new buffname)))
          (set! tempLayer (car (gimp-image-get-active-layer tempImage)))        
          )
        )
        (set! tempdisplay (car (gimp-display-new tempImage)))
        (if (> inPadding 0)
        (begin
          (script-fu-addborder tempImage tempLayer inPadding inPadding inBgCol 0)
          (gimp-image-merge-visible-layers tempImage EXPAND-AS-NECESSARY)
          (set! tempLayer (car (gimp-image-get-active-layer tempImage)))
        ))
        (gimp-image-undo-enable tempImage)
          
        ;save file
        (if (= inSaveFiles TRUE)
        (begin
          (let* ((targetDir inDir))
            (if (= inSaveInSourceDir TRUE)
              (set! targetDir (unbreakupstr (butlast (strbreakup imgpath pathchar)) pathchar))
            )
            
            (set! newFileName (string-append targetDir pathchar (car(gimp-image-get-name img)) inFileName
                                     (substring "00000" (string-length (number->string (+ inFileNumber numextracted))))
                                     (number->string (+ inFileNumber numextracted)) saveString))
            (gimp-image-set-resolution tempImage 600 600)  ; The DPI
            (if (equal? saveString ".jpg") 
            (file-jpeg-save RUN-NONINTERACTIVE tempImage tempLayer newFileName newFileName inJpgQual 0.1 1 0 "Custom JPG compression by FrancoisM" 0 1 0 1)
            (gimp-file-save RUN-NONINTERACTIVE tempImage tempLayer newFileName newFileName)
            )
            (if (= inAutoClose TRUE)
            (begin
              (gimp-display-delete tempdisplay)
            )
            )
          )
        ))
          
        (set! numextracted (+ numextracted 1))
        )
      )     
      (gimp-image-remove-vectors img (car tempVector))
      (set! count (+ count 1))
    )

    ;input drawable name should be set to 1919191919 if in batch
    (if (and (> numextracted 0) (equal? (car (gimp-drawable-get-name inLayer)) "1919191919"))
      (gimp-drawable-set-name inLayer (number->string (+ 1919191919 numextracted))))

    ;delete temp path
    (gimp-image-remove-vectors img newpath)
    (gimp-selection-none img)
    
    ;done
    (gimp-image-undo-enable img)
    (gimp-progress-end)
    (gimp-displays-flush)
    (gimp-context-pop)
  )
)

(script-fu-register "script_fu_DivideScannedImages"
                    "<Image>/Filters/Divide Scanned Images..."
                    "Attempts to isolate images from a uniform background and saves a new square image for each"
                    "Francois Malan"
                    "Francois Malan"
                    "Feb 2016"
                    "RGB* GRAY*"
                    SF-IMAGE      "image"      0
                    SF-DRAWABLE   "drawable"   0
                    SF-TOGGLE "Force square crop"                       FALSE
                    SF-ADJUSTMENT "Square border padding (pixels)"      (list 0 0 100 1 10 0 SF-SLIDER)
                    SF-ADJUSTMENT "Max number of items"                 (list 10 1 100 1 10 0 SF-SLIDER)
                    SF-TOGGLE "Run Deskew"                              TRUE
                    SF-TOGGLE "Auto-close sub-images after saving"      TRUE
                    SF-ADJUSTMENT "Selection Threshold"                 (list 25 0 255 1 10 1 SF-SLIDER)
                    SF-ADJUSTMENT "Size Threshold"                      (list 100 0 2000 10 100 1 SF-SLIDER)
                    SF-TOGGLE "Manually define background colour"       FALSE
                    SF-COLOR "Manual background colour"                 '(255 255 255)
                    SF-OPTION     "Auto-background sample corner"       (list "Top Left" "Top Right" "Bottom Left" "Bottom Right")
                    SF-ADJUSTMENT "Auto-background sample x-offset"     (list 25 5 100 1 10 1 SF-SLIDER)
                    SF-ADJUSTMENT "Auto-background sample y-offset"     (list 25 5 100 1 10 1 SF-SLIDER)
                    SF-TOGGLE     "Save output to source directory"     TRUE
                    SF-DIRNAME    "Target directory (if not to source)" ""
                    SF-OPTION     "Save File Type"                      (list  "jpg" "png")
                    SF-ADJUSTMENT "JPG Quality"                         (list 0.8 0.1 1.0 1 10 1 SF-SLIDER)
                    SF-STRING     "Save File Base Name"                 "Crop"
                    SF-ADJUSTMENT "Save File Start Number"              (list 1 0 9000 1 100 0 SF-SPINNER)                  
)
(define (script_fu_BatchDivideScannedImages inSourceDir inLoadType inSquareCrop inPadding inLimit inDeskew inAutoClose inThreshold inSize inDefBg inBgCol inCorner inX inY inSaveInSourceDir inDestDir inSaveType inJpgQual inFileName)
(let*
    (
      (varLoadStr "")
      (varFileList 0)
      (pathchar (if (equal? (substring gimp-dir 0 1) "/") "/" "\\"))
    )
    
    (define split
      (lambda (ls)
        (letrec ((split-h (lambda (ls ls1 ls2)
                            (cond
                              ((or (null? ls) (null? (cdr ls)))
                               (cons (reverse ls2) ls1))
                              (else (split-h (cddr ls)
                                      (cdr ls1) (cons (car ls1) ls2)))))))
          (split-h ls ls '()))))
          
    (define merge
      (lambda (pred ls1 ls2)
        (cond
          ((null? ls1) ls2)
          ((null? ls2) ls1)
          ((pred (car ls1) (car ls2))
           (cons (car ls1) (merge pred (cdr ls1) ls2)))
          (else (cons (car ls2) (merge pred ls1 (cdr ls2)))))))

    ;pred is the comparison, i.e. <= for an ascending numeric list, or 
    ;string<=? for a case sensitive alphabetical sort, 
    ;string-ci<=? for a case insensitive alphabetical sort, 
    (define merge-sort
      (lambda (pred ls)
        (cond
          ((null? ls) ls)
          ((null? (cdr ls)) ls)
          (else (let ((splits (split ls)))
                  (merge pred
                    (merge-sort pred (car splits))
                    (merge-sort pred (cdr splits))))))))

    ;begin here
    (set! varLoadStr
    (cond 
    (( equal? inLoadType 0 ) ".[jJ][pP][gG]" )
    (( equal? inLoadType 1 ) ".[jJ][pP][eE][gG]" )
    (( equal? inLoadType 2 ) ".[bB][mM][pP]" )
    (( equal? inLoadType 3 ) ".[pP][nN][gG]" )
    (( equal? inLoadType 4 ) ".[tT][iI][fF]" )
    (( equal? inLoadType 5 ) ".[tT][iI][fF][fF]" )
    ))  

    (set! varFileList (merge-sort string<=? (cadr (file-glob (string-append inSourceDir pathchar "*" varLoadStr)  1))))
    (while (not (null? varFileList))
      (let* ((filename (car varFileList))
             (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
             (drawable (car (gimp-image-get-active-layer image))))

        ;flag for batch mode
        (gimp-drawable-set-name drawable "1919191919")
        (gimp-progress-set-text (string-append "Working on ->" filename))
      
        (script_fu_DivideScannedImages image drawable inSquareCrop inPadding inLimit inDeskew inAutoClose inThreshold inSize inDefBg inBgCol inCorner inX inY inSaveInSourceDir inDestDir inSaveType inJpgQual inFileName 1)
 
        (gimp-image-delete image)
      )
      (set! varFileList (cdr varFileList))
    )
  )
)
(script-fu-register "script_fu_BatchDivideScannedImages"
                    "<Toolbox>/Xtns/Batch Tools/Batch Divide Scanned Images..."
                    "Batch-divide a folder of full-page scans of images."
                    "Francois Malan"
                    "Francois Malan"
                    "Feb 2016"
                    ""
                    SF-DIRNAME    "Load from" ""
                    SF-OPTION     "Load File Type" (list "jpg" "jpeg" "bmp" "png" "tif" "tiff") 
                    SF-TOGGLE "Force square crop"                       FALSE
                    SF-ADJUSTMENT "Square border padding (pixels)"      (list 0 0 100 1 10 0 SF-SLIDER)
                    SF-ADJUSTMENT "Max number of items"                 (list 10 1 100 1 10 0 SF-SLIDER)  
                    SF-TOGGLE "Run Deskew"                              TRUE
                    SF-TOGGLE "Auto-close sub-images after saving"      TRUE
                    SF-ADJUSTMENT "Selection Threshold"                 (list 25 0 255 1 10 1 SF-SLIDER)
                    SF-ADJUSTMENT "Size Threshold"                      (list 100 0 2000 10 100 1 SF-SLIDER)        
                    SF-TOGGLE "Manually define background colour"       FALSE
                    SF-COLOR "Manual background colour"                 '(255 255 255)
                    SF-OPTION     "Auto-background sample corner"       (list "Top Left" "Top Right" "Bottom Left" "Bottom Right")
                    SF-ADJUSTMENT "Auto-background sample x-offset"     (list 25 5 100 1 10 1 SF-SLIDER)
                    SF-ADJUSTMENT "Auto-background sample y-offset"     (list 25 5 100 1 10 1 SF-SLIDER)
                    SF-TOGGLE     "Save output to source directory"     TRUE
                    SF-DIRNAME    "Target directory (if not to source)" ""
                    SF-OPTION     "Save File Type"                      (list "jpg" "png" "same as input")
                    SF-ADJUSTMENT "JPG Quality"                         (list 0.8 0.1 1.0 1 10 1 SF-SLIDER)
                    SF-STRING     "Save File Base Name"                 "Crop"
)
