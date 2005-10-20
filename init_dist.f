C Initial size distributions.

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine init_bidisperse(MM, n_bin, n_ini)

      integer MM           ! INPUT: physical dimension of V
      integer n_bin        ! INPUT: number of bins
      integer n_ini(n_bin) ! OUTPUT: initial number distribution

      integer k

      if (MM .lt. 126) then
         write(*,*)'ERROR: MM too small for bidisperse'
         call exit(2)
      endif

      do k = 1,n_bin
         n_ini(k) = 0
      enddo
      n_ini(97) = MM - 1
      n_ini(126) = 1

      return
      end

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      subroutine init_exp(MM, V_0, dlnr, n_bin, bin_v, bin_r, n_ini)

      integer MM           ! INPUT: physical dimension of V
      real*8 V_0           ! INPUT: mean volume of initial distribution
      real*8 dlnr          ! INPUT: bin scale factor
      integer n_bin        ! INPUT: number of bins
      real*8 bin_v(n_bin)  ! INPUT: volume of particles in bins
      real*8 bin_r(n_bin)  ! INPUT: radius of particles in bins
      integer n_ini(n_bin) ! OUTPUT: initial number distribution

      integer k

      real*8 pi
      parameter (pi = 3.14159265358979323846d0)

      do k = 1,n_bin
         n_ini(k) = int(4d0 * pi * bin_r(k)**3 * MM/V_0
     &        * exp(-(bin_v(k) / V_0)) * dlnr)
      enddo

      return
      end

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
