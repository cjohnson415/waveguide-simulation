(define-param core_diameter 4.0) ; unit of length is mm
(define-param above_cutoff 6.66) ; wavelength in mm (45 GHz)
(define-param below_cutoff 8.57) ; wavelength in mm (35 GHz)
(define-param wave_length below_cutoff) ; wavelength in mm
(define-param dpml 1) ; thickness of PML

(define-param cx (+ core_diameter 2.0)) ; size of cell in X direction
(define-param cy (+ core_diameter 2.0)) ; size of cell in Y direction
(define-param cz (* wave_length 20.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) wave_length dpml)) ;
(define-param fcen (/ 1 wave_length)) ; pulse center frequency
(define-param df 0.1)  ; pulse width (in frequency)
(define-param smooth_t 30)

(set! geometry-lattice (make lattice (size cx cy cz)))

(set! geometry (list
	(make cylinder (center 0 0 (+ source_z (/ cz 2))) (radius infinity) (height cz)
		(material metal))
	(make cylinder (center 0 0 0) (radius (/ core_diameter 2)) (height infinity)
		(material air))))

(set! sources (list
		(make source
			(src (make continuous-src (frequency fcen) (width smooth_t)))
			(component Ey)
			(center 0 0 source_z)
			(size (/ core_diameter 2) (/ core_diameter 2) (/ wave_length 2)))))

(set! pml-layers (list (make pml (thickness 1.0))))

(set! resolution 5)

(run-until 600
	(at-beginning output-epsilon)
	(to-appended "ey" (at-every 0.5 output-efield-y)))
