(define-param THZ .6) ; wavelength in mm (.5 THz)
(define-param intermediate 3);
(define-param wave_length intermediate) ; wavelength in mm
(define-param dpml 1) ; thickness of PML

(define-param pitch 1)
(define-param major_r 3)
(define-param minor_r 0.4)

(define-param cx (+ (* 2 major_r) (* 2 minor_r) 6.0)) ; size of cell in X direction
(define-param cy cx) ; size of cell in Y direction
(define-param cz (* wave_length 20.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) wave_length dpml)) ;
(define-param fcen (/ 1 wave_length)) ; pulse center frequency
(define-param df 0.1)  ; pulse width (in frequency)
(define-param smooth_t 30)

(define-param b_helix (/ pitch (* 2 pi)))
(define-param theta_helix (asin (/ b_helix (sqrt (+ (expt major_r 2) (expt b_helix 2))))))

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

(set! sources (list
		(make source
			(src (make continuous-src (frequency fcen) (width smooth_t)))
			(component Ey)
			(center 0 0 source_z)
			(size (* 2 major_r) (* 2 major_r) 0))))

(set! pml-layers (list (make pml (thickness 1.0))))

(set! resolution 10)

(use-output-directory)
(run-until 1
	(at-beginning output-epsilon)
	(at-every 0.5 
		(to-appended "xEx" (in-volume (center 0 0 0) (size cx 0 cz) output-efield-x))
		(to-appended "yEx" (in-volume (center 0 0 0) (size 0 cy cz) output-efield-x))))
