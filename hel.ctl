(define-param THZ .75) ; wavelength in mm (.4 THz)
(define-param intermediate 3);
(define-param wave_length THZ) ; wavelength in mm
(define-param dpml 1) ; thickness of PML
(define-param pml_pad 4)

(define-param pitch 1)
(define-param major_r 3)
(define-param minor_r 0.4)

(define-param cx (+ (* 2 major_r) (* 2 minor_r) (* 2 pml_pad))) ; size of cell in X direction
(define-param cy cx) ; size of cell in Y direction
(define-param cz (* wave_length 80.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) wave_length dpml)) ;
(define-param fcen (/ 1 wave_length)) ; pulse center frequency
(define-param df 1)  ; +/- .24 THz
(define-param smooth_t 20)

(define-param b_helix (/ pitch (* 2 pi)))
(define-param theta_helix (asin (/ b_helix (sqrt (+ (expt major_r 2) (expt b_helix 2))))))



(define-param cw? false) ;if false, gaussian
(define-param wvg? true) ;if false, no waveguide

(if wvg? (print "wvgtrue!") (print "wvgfalse!"))
(if cw? (print "cwtrue!") (print "cwfalse!"))

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
	(if cw?
		(list
		  (make source
			  (src (make continuous-src (frequency fcen) (width smooth_t)))
			  (component Ex)
			  (center 0 0 source_z)
			  (size (* 2 major_r) (* 2 major_r) 0))
		  (make source
			  (src (make continuous-src (frequency fcen) (width smooth_t)))
			  (component Ey)
			  (center 0 0 source_z)
			  (size (* 2 major_r) (* 2 major_r) 0)))
		(list
		  (make source
			  (src (make gaussian-src (frequency fcen) (fwidth df)))
			  (component Ex)
			  (center 0 0 source_z)
			  (size 2 major_r 2 major_r 0))
		  (make source
			  (src (make gaussian-src (frequency fcen) (fwidth df)))
			  (component Ey)
			  (center 0 0 source_z)
			  (size 2 major_r 2 major_r 0)))))

(set! pml-layers (list (make pml (thickness dpml))))

(set! resolution 10)



(define-param nfreq 100) ; number of frequencies at which to compute flux
(define-param trans_z (- (/ cz 2) dpml pml_pad))
(define-param incident_z (+ source_z .5))

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
(if cw?
  (run-until 500
	  (at-beginning output-epsilon)
	  (at-every 0.5
		  (with-prefix "xEy" (output-png Ey "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "yEy" (output-png Ey "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "xEx" (output-png Ex "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "yEx" (output-png Ex "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS"))))
  (run-until 600
	  (at-every 0.5
		  (with-prefix "xEy" (output-png Ey "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "yEy" (output-png Ey "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "xEx" (output-png Ex "-0y0 -R -Zc dkbluered -a green:0.5 -A $EPS"))
		  (with-prefix "yEx" (output-png Ex "-0x0 -R -Zc dkbluered -a green:0.5 -A $EPS")))
	  (at-beginning output-epsilon)))

(if (not cw?) (display-fluxes f1 f2))
