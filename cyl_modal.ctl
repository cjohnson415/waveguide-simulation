(define-param core_diameter 4.0) ; unit of length is mm
(define-param wave_length 10.0) ; wavelength in mm
(define-param dpml 2) ; thickness of PML

(define-param cx (+ core_diameter 2.0)) ; size of cell in X direction
(define-param cy (+ core_diameter 2.0)) ; size of cell in Y direction
(define-param cz (* wave_length 4.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) (* 2 dpml))) ;
(define-param fcen (/ 1 wave_length)) ; pulse center frequency
(define-param df 0.1)  ; pulse width (in frequency)

(set! geometry-lattice (make lattice (size cx cy cz)))

(set! geometry (list
	(make cylinder (center 0 0 0) (radius infinity) (height cz)
		(material metal))
	(make cylinder (center 0 0 0) (radius (/ core_diameter 2)) (height infinity)
		(material air))))

(set! pml-layers (list (make pml (thickness dpml))))

(set! sources (list
	(make source
		(src (make gaussian-src (frequency fcen) (fwidth df)))
		(component Ey) (center .1 .1 .1))))

(set! resolution 10)

(run-sources+ 300
	(at-beginning output-epsilon)
	(after-sources (harminv Ey (vector3 0 0 0) fcen df))
	(after-sources (harminv Ey (vector3 .1 .1 .1) fcen df)))
