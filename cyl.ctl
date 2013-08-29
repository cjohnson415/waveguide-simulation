(define-param core_diameter 4.0) ; unit of length is mm
(define-param above_cutoff 6.66) ; wavelength in mm (45 GHz)
(define-param below_cutoff 8.57) ; wavelength in mm (35 GHz)
(define-param intermediate 3) ; (~100 GHz)
(define-param THZ .6) ; wavelength in mm (.5 THz)
(define-param wave_length intermediate) ; wavelength in mm
(define-param dpml 1) ; thickness of PML
(define-param d_lambda 2.0)
(define-param outer_diameter (+ core_diameter 2))
(define-param wvg_pad 8)

(define-param cx (+ outer_diameter dpml wvg_pad)) ; size of cell in X direction
(define-param cy cx) ; size of cell in Y direction
(define-param cz (* wave_length 30.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) wave_length dpml wvg_pad)) ;
(define-param fcen (/ 1.0 wave_length)) ; pulse center frequency
(define-param df (/ 1 d_lambda))  ; pulse width (in frequency)
(define-param smooth_t 30)

(set! geometry-lattice (make lattice (size cx cy cz)))

(define-param wvg? true) ;if false, no waveguide

(if wvg? (print "wvgtrue!") (print "wvgfalse!"))

(set! geometry
	  (list
	  (make cylinder (center 0 0 (+ source_z (/ cz 2))) (radius (/ outer_diameter 2)) (height (if wvg? cz 1))
		  (material (make medium (D-conductivity 2.26e7))))
	  (make cylinder (center 0 0 0) (radius (/ core_diameter 2)) (height infinity)
		  (material air))))

(set! sources (list
		(make source
			(src (make gaussian-src (frequency fcen) (fwidth df)))
			(component Ex)
			(center 0 0 source_z)
			(size core_diameter core_diameter 0))
		(make source
			(src (make gaussian-src (frequency fcen) (fwidth df)))
			(component Ey)
			(center 0 0 source_z)
			(size core_diameter core_diameter 0))))

(set! pml-layers (list (make pml (thickness 1.0))))

(set! resolution 5)

(define-param nfreq 100) ; number of frequencies at which to compute flux
(define-param trans_z (- (/ cz 2) (* 3 dpml)))
(define-param incident_z (+ source_z .5))

(define transmitted ; transmitted flux
	(add-flux fcen df nfreq
		(make flux-region
			(if wvg? (center 0 0 trans_z) (center 0 0 incident_z)) (size (* outer_diameter 2) (* outer_diameter 2) 0))))

(run-until
	(stop-when-fields-decayed 50 Ey (vector3 0 0 (if wvg? trans_z incident_z)) (if wvg? 2e-3 1e-3))
	(to-appended "ey" (at-every 1 output-efield-y))
	(to-appended "ex" (at-every 1 output-efield-x))
	(at-beginning output-epsilon))

(display-fluxes transmitted)
