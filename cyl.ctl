(define-param core_diameter 4.0) ; unit of length is mm
(define-param above_cutoff 6.66) ; wavelength in mm (45 GHz)
(define-param below_cutoff 8.57) ; wavelength in mm (35 GHz)
(define-param intermediate 3) ; (~100 GHz)
(define-param THZ .6) ; wavelength in mm (.5 THz)
(define-param wave_length intermediate) ; wavelength in mm
(define-param dpml 1) ; thickness of PML
(define-param outer_diameter (+ core_diameter 2))
(define-param wvg_pad 1)

(define-param cx (+ outer_diameter dpml wvg_pad)) ; size of cell in X direction
(define-param cy cx) ; size of cell in Y direction
(define-param cz (* wave_length 40.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) (* 2 wave_length) dpml)) ;
(define-param fcen (/ 1 wave_length)) ; centered at 240 GHz
(define-param df 0.6); +/- 90 GHz

(set! geometry-lattice (make lattice (size cx cy cz)))

(set! geometry
	  (list
	  (make cylinder (center 0 0 (+ source_z (/ cz 2))) (radius (/ outer_diameter 2)) (height cz)
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

(define-param nfreq 200) ; number of frequencies at which to compute flux

(define f1
	(add-flux fcen df nfreq
		(make flux-region
			(center 0 0 0)
			(size core_diameter core_diameter 0))))

; delta_x = 40mm
(define-param f2_z (/ cz 3))
(print f2_z)

(define f2
	(add-flux fcen df nfreq
		(make flux-region
			(center 0 0 f2_z)
			(size core_diameter core_diameter 0))))

(use-output-directory)
(run-until 200
	(at-beginning output-epsilon)
	(at-every 0.5
		(with-prefix "xEy" (output-png Ey "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		(with-prefix "yEy" (output-png Ey "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		(with-prefix "xEx" (output-png Ex "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		(with-prefix "yEx" (output-png Ex "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS"))))

(display-fluxes f1 f2)
(print f2_z)
