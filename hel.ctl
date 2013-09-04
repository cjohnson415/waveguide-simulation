(define-param THZ .75) ; wavelength in mm (.4 THz)
(define-param intermediate 3);
(define-param wave_length THZ) ; wavelength in mm
(define-param dpml 1) ; thickness of PML
(define-param pml_pad 1)

(define-param major_r 3)
(define-param minor_r 0.2)
(define-param spacing .6)
(define-param pitch (+ spacing (* minor_r 2)))

(define-param cx (* 2 (+ major_r minor_r pml_pad dpml))) ; size of cell in X direction
(define-param cy cx) ; size of cell in Y direction
(define-param cz (* wave_length 80.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) 8)) ;
(define-param fcen (/ 1 wave_length)) ; pulse center frequency
(define-param df 1)  ; +/- .24 THz
(define-param smooth_t 20)

(define-param b_helix (/ pitch (* 2 pi)))
(define-param theta_helix (asin (/ b_helix (sqrt (+ (expt major_r 2) (expt b_helix 2))))))



(define-param mov? true); if false, no pngs are output


(define (get_t position)
	(/ (vector3-z position) b_helix))

(define-param dt .01)
(define (list-of-cyls t_max)
	(let loop ((t t_max) (res '()))
		(if (< t 0)
			res
			(loop (- t dt)
				(cons (make cylinder
					(center (* major_r (cos t)) (* major_r (sin t)) (+ (* b_helix t) source_z))
					(radius minor_r)
					(height (* dt (sqrt (+ (expt major_r 2) (expt b_helix 2)))))
					(axis (* -1 major_r (sin t)) (* major_r (cos t)) b_helix)
					(material metal)) res)))))

(set! geometry-lattice (make lattice (size cx cy cz)))

(set! eps-averaging? false)

(define (make-helix axial-length)
	(list-of-cyls (/ axial-length b_helix)))

(set! geometry (make-helix (- cz wave_length dpml)))

(set! sources
	(list
	  (make source
		  (src (make gaussian-src (frequency fcen) (fwidth df)))
		  (component Ex)
		  (center 0 0 source_z)
		  (size major_r major_r 0))
	  (make source
		  (src (make gaussian-src (frequency fcen) (fwidth df)))
		  (component Ey)
		  (center 0 0 source_z)
		  (size major_r major_r 0))))

(set! pml-layers (list (make pml (thickness dpml))))

(set! resolution 14)

(define-param nfreq 200) ; number of frequencies at which to compute flux

(define f1
	(add-flux fcen df nfreq
		(make flux-region
			(center 0 0 0)
			(size (* major_r 2) (* major_r 2) 0))))

(define-param f2_z (* (/ cz 6) 2))
(print f2_z)

(define f2
	(add-flux fcen df nfreq
		(make flux-region
			(center 0 0 f2_z)
			(size (* major_r 2) (* major_r 2) 0))))

(use-output-directory)
(run-until 200
	(if mov?
	  (at-every 0.25
		  (with-prefix "xEy" (output-png Ey "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "yEy" (output-png Ey "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "xEx" (output-png Ex "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "yEx" (output-png Ex "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS"))))
	(at-beginning output-epsilon))

(display-fluxes f1 f2)
