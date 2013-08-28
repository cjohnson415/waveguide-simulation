(define-param THZ .6) ; wavelength in mm (.5 THz)
(define-param intermediate 3);
(define-param wave_length intermediate) ; wavelength in mm
(define-param dpml 1) ; thickness of PML

(define-param pitch 4)
(define-param major_r 3)
(define-param minor_r 0.4)

(define-param cx (+ (* 2 major_r) (* 2 minor_r) 4.0)) ; size of cell in X direction
(define-param cy cx) ; size of cell in Y direction
(define-param cz (* wave_length 5.0)) ; size of cell in Z direction

(define-param source_z (+ (/ cz -2.0) wave_length dpml)) ;
(define-param fcen (/ 1 wave_length)) ; pulse center frequency
(define-param df 0.1)  ; pulse width (in frequency)
(define-param smooth_t 30)

(define-param b_helix (/ pitch (* 2 pi)))
(define-param theta_helix (asin (/ b_helix (sqrt (+ (expt major_r 2) (expt b_helix 2))))))

(define (get_t position)
	(/ (vector3-z position) b_helix))

(define-param dt 1)
(define (list-of-cyls t_max)
	(let loop ((i t_max) (res '()))
		(if (< i 0)
			res
			(loop (- i dt)
				(cons (make block (center 0 0 i) (size 1 1 1) (material metal)) res)))))

(set! geometry-lattice (make lattice (size cx cy cz)))

(set! geometry (list-of-cyls 5))

(set! sources (list
		(make source
			(src (make continuous-src (frequency fcen) (width smooth_t)))
			(component Ey)
			(center 0 0 source_z)
			(size (* 2 major_r) (* 2 major_r) 0))))

(set! pml-layers (list (make pml (thickness 1.0))))

(set! resolution 10)

(run-until 1
	(at-beginning output-epsilon)
	(to-appended "ey" (at-every 0.2 output-efield-y))
	(to-appended "ex" (at-every 0.2 output-efield-x)))
