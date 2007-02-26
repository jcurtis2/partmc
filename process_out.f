! -*- mode: f90; -*-
! Copyright (C) 2005-2007 Nicole Riemer and Matthew West
! Licensed under the GNU General Public License version 2 or (at your
! option) any later version. See the file COPYING for details.
!
! Process output data files.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

program process_out

  use mod_util
  
  integer, parameter :: f_in = 20       ! input
  integer, parameter :: f_out_num = 21  ! output number
  integer, parameter :: f_out_vol = 22  ! output vol
  integer, parameter :: f_out_temp = 23 ! output temperature
  integer, parameter :: f_out_rh = 24   ! output relative humidity
  integer, parameter :: f_out_time = 25 ! output time
  integer, parameter :: f_out_num_avg = 26 ! output number average
  integer, parameter :: f_out_vol_avg = 27 ! output vol average
  integer, parameter :: f_out_temp_avg = 28 ! output temperature average
  integer, parameter :: f_out_rh_avg = 29 ! output relative humidity average
  integer, parameter :: f_out_time_avg = 30 ! output time average
  
  integer :: n_bin, n_loop, n_time, n_spec
  character(len=1000) :: name_in
  character(len=1000) :: name_out_time, name_out_time_avg
  character(len=1000) :: name_out_num, name_out_vol
  character(len=1000) :: name_out_temp, name_out_rh
  character(len=1000) :: name_out_num_avg, name_out_vol_avg
  character(len=1000) :: name_out_temp_avg, name_out_rh_avg
  character(len=1000) :: dum, n_loop_str, n_time_str
 
  real*8, allocatable :: time(:,:), time_avg(:)
  real*8, allocatable :: bin_r(:)
  real*8, allocatable :: bin_g(:,:,:)
  real*8, allocatable :: bin_gs(:,:,:,:)
  real*8, allocatable :: n(:,:,:)
  real*8, allocatable :: g_avg(:,:)
  real*8, allocatable :: gs_avg(:,:,:)
  real*8, allocatable :: n_avg(:,:)
  real*8, allocatable :: temp(:,:), temp_avg(:)
  real*8, allocatable :: rh(:,:), rh_avg(:)
 
  integer :: i, i_loop, i_time, i_bin, i_spec, dum_int
  
  ! check there is exactly one commandline argument
  if (iargc() .ne. 1) then
     write(6,*) 'Usage: process_out <filename.d>'
     call exit(2)
  endif
  
  ! get and check first commandline argument (must be "filename.d")
  call getarg(1, name_in)
  i = len_trim(name_in)
  if (i .gt. 40) then
     write(6,*) 'ERROR: filename too long'
     call exit(2)
  endif
  if ((name_in(i:i) .ne. 'd') .or. &
       (name_in((i-1):(i-1)) .ne. '.')) then
     write(6,*) 'ERROR: Filename must end in .d'
     call exit(2)
  endif
  
  ! compute names of output files
  name_out_num = name_in
  name_out_vol = name_in
  name_out_temp = name_in
  name_out_rh = name_in
  name_out_time = name_in
  name_out_num_avg = name_in
  name_out_vol_avg = name_in
  name_out_temp_avg = name_in
  name_out_rh_avg = name_in
  name_out_time_avg = name_in
  name_out_num((i-1):) = '_num.d'
  name_out_vol((i-1):) = '_vol.d'
  name_out_temp((i-1):) = '_temp.d'
  name_out_rh((i-1):) = '_rh.d'
  name_out_time((i-1):) = '_time.d'
  name_out_num_avg((i-1):) = '_num_avg.d'
  name_out_vol_avg((i-1):) = '_vol_avg.d'
  name_out_temp_avg((i-1):) = '_temp_avg.d'
  name_out_rh_avg((i-1):) = '_rh_avg.d'
  name_out_time_avg((i-1):) = '_time_avg.d'
  
  write(6,*) 'name_in = ', trim(name_in)
  write(6,*) 'name_out_num = ', trim(name_out_num)
  write(6,*) 'name_out_vol = ', trim(name_out_vol)
  write(6,*) 'name_out_temp = ', trim(name_out_temp)
  write(6,*) 'name_out_rh = ', trim(name_out_rh)
  write(6,*) 'name_out_time = ', trim(name_out_time)
  write(6,*) 'name_out_num_avg = ', trim(name_out_num_avg)
  write(6,*) 'name_out_vol_avg = ', trim(name_out_vol_avg)
  write(6,*) 'name_out_temp_avg = ', trim(name_out_temp_avg)
  write(6,*) 'name_out_rh_avg = ', trim(name_out_rh_avg)
  write(6,*) 'name_out_time_avg = ', trim(name_out_time_avg)
  
  ! open files
  call open_existing(f_in, name_in)
  open(f_out_num, file=name_out_num)
  open(f_out_vol, file=name_out_vol)
  open(f_out_temp, file=name_out_temp)
  open(f_out_rh, file=name_out_rh)
  open(f_out_time, file=name_out_time)
  open(f_out_num_avg, file=name_out_num_avg)
  open(f_out_vol_avg, file=name_out_vol_avg)
  open(f_out_temp_avg, file=name_out_temp_avg)
  open(f_out_rh_avg, file=name_out_rh_avg)
  open(f_out_time_avg, file=name_out_time_avg)
  
  ! read and check dimensions
  read(f_in, '(a10,i10)') dum, n_loop
  read(f_in, '(a10,i10)') dum, n_bin
  read(f_in, '(a10,i10)') dum, n_time
  read(f_in, '(a10,i10)') dum, n_spec
  
  allocate(time(n_loop, n_time))
  allocate(time_avg(n_time))
  allocate(bin_r(n_bin))
  allocate(bin_g(n_loop, n_time, n_bin))
  allocate(bin_gs(n_loop, n_time, n_bin, n_spec))
  allocate(n(n_loop, n_time, n_bin))
  allocate(g_avg(n_time, n_bin))
  allocate(gs_avg(n_time,n_bin,n_spec))
  allocate(n_avg(n_time, n_bin))
  allocate(temp(n_loop, n_time))
  allocate(temp_avg(n_time))
  allocate(rh(n_loop, n_time))
  allocate(rh_avg(n_time))

  write(6,*) 'n_loop = ', n_loop
  write(6,*) 'n_bin =  ', n_bin
  write(6,*) 'n_time = ', n_time
  write(6,*) 'n_spec = ', n_spec
  
  write(n_loop_str, '(i10)') n_loop
  write(n_time_str, '(i10)') n_time
  
  ! read all data
  do i_loop = 1,n_loop
     do i_time = 1,n_time
        read(f_in, '(a10,i20)') dum, dum_int
        read(f_in, '(a10,e20.10)') dum, time(i_loop, i_time)
        read(f_in, '(a10,e20.10)') dum, temp(i_loop, i_time)
        read(f_in, '(a10,e20.10)') dum, rh(i_loop, i_time)
        read(f_in, '(a)') dum
        do i_bin = 1,n_bin
           read(f_in, '(i10,50e20.10)') i, bin_r(i_bin), &
                n(i_loop, i_time, i_bin), &
                bin_g(i_loop, i_time, i_bin), &
                (bin_gs(i_loop,i_time, i_bin, i_spec), &
                i_spec=1,n_spec)
        enddo
     enddo
  enddo
  
  ! compute simple loop averages
  do i_time = 1,n_time
     temp_avg(i_time) = 0d0
     rh_avg(i_time) = 0d0
     time_avg(i_time) = 0d0
     do i_loop = 1,n_loop
        temp_avg(i_time) = temp_avg(i_time) + temp(i_loop, i_time)
        rh_avg(i_time) = rh_avg(i_time) + rh(i_loop, i_time)
        time_avg(i_time) = time_avg(i_time) + time(i_loop, i_time)
     enddo
     temp_avg(i_time) = temp_avg(i_time) / dble(n_loop)
     rh_avg(i_time) = rh_avg(i_time) / dble(n_loop)
     time_avg(i_time) = time_avg(i_time) / dble(n_loop)
  enddo
  
  ! compute binned loop averages
  do i_time = 1,n_time
     do i_bin = 1,n_bin
        g_avg(i_time, i_bin) = 0d0
        n_avg(i_time, i_bin) = 0d0
        do i_spec = 1,n_spec
           gs_avg(i_time,i_bin, i_spec) = 0d0
        enddo
        do i_loop = 1,n_loop
           g_avg(i_time, i_bin) = g_avg(i_time, i_bin) &
                + bin_g(i_loop, i_time, i_bin)
           n_avg(i_time, i_bin) = n_avg(i_time, i_bin) &
                + n(i_loop, i_time, i_bin)
           do i_spec = 1,n_spec
              gs_avg(i_time, i_bin, i_spec) =  &
                   gs_avg(i_time, i_bin, i_spec) &
                   +bin_gs(i_loop,i_time,i_bin,i_spec)
           enddo
        enddo
        g_avg(i_time, i_bin) = g_avg(i_time, i_bin) / dble(n_loop)
        n_avg(i_time, i_bin) = n_avg(i_time, i_bin) / dble(n_loop)
        do i_spec=1,n_spec
           gs_avg(i_time,i_bin,i_spec) =  &
                gs_avg(i_time,i_bin,i_spec) / dble(n_loop)
        enddo
     enddo
  enddo
  
  ! output raw number and vol data
  do i_time = 1,n_time
     write(f_out_num, '(//,a10,i10)') 'time', i_time - 1
     write(f_out_vol, '(//,a10,i10)') 'time', i_time - 1
     write(f_out_num, '(a1,a9,a20,a40)') '#', 'bin_num', 'radius(m)', &
          'num den per loop (#/m^3)'
     write(f_out_vol, '(a1,a9,a20,a40)') '#', 'bin_num', 'radius(m)', &
          'vol den per loop (m^3/m^3)'
     do i_bin = 1,n_bin
        write(f_out_num, '(i10,e20.10,'//n_loop_str//'e20.10)') &
             i_bin, bin_r(i_bin), &
             (n(i_loop, i_time, i_bin), i_loop = 1,n_loop)
        write(f_out_vol, '(i10,e20.10,'//n_loop_str//'e20.10)') &
             i_bin, bin_r(i_bin), &
             (bin_g(i_loop, i_time, i_bin), i_loop = 1,n_loop)
     enddo
     do i_spec = 1,n_spec
        write(f_out_vol,*)
        write(f_out_vol,*)
        write(f_out_vol, '(a1,a19)') '#', 'time', i_time - 1
        write(f_out_vol, '(a1,a19)') '#', 'species num', i_spec
        write(f_out_vol, '(a1,a9,a20,a40)') '#', 'bin_num', 'radius(m)', &
             'vol den per loop (m^3/m^3)'
        do i_bin=1,n_bin
           write(f_out_vol, '(i10,e20.10,'//n_loop_str//'e20.10)') &
                i_bin, bin_r(i_bin), &
                (bin_gs(i_loop, i_time, i_bin,i_spec) &
                ,i_loop =1,n_loop)
        enddo
     enddo
  enddo
  
  ! output averaged number and vol data
  write(f_out_num_avg, '(a1,a9,a20,a40)') '#', 'bin_num', 'radius(m)', &
       'num den at each time (#/m^3)'
  write(f_out_vol_avg, '(a1,a9,a20,a40)') '#', 'bin_num', 'radius(m)', &
       'vol den at each time (m^3/m^3)'
  do i_bin = 1,n_bin
     write(f_out_num_avg, '(i10,e20.10,'//n_time_str//'e20.10)') &
          i_bin, bin_r(i_bin), &
          (n_avg(i_time, i_bin), i_time = 1,n_time)
     write(f_out_vol_avg, '(i10,e20.10,'//n_time_str//'e20.10)') &
          i_bin, bin_r(i_bin), &
          (g_avg(i_time, i_bin), i_time = 1,n_time)
  enddo
  do i_spec = 1,n_spec
     write(f_out_vol_avg,*)
     write(f_out_vol_avg,*)
     write(f_out_vol, '(a1,a19)') '#', 'species num', i_spec
     write(f_out_vol, '(a1,a9,a20,a40)') '#', 'bin_num', 'radius(m)', &
          'species vol den at each time (m^3/m^3)'
     do i_bin=1,n_bin
        write(f_out_vol_avg, '(i10,e20.10,'//n_time_str//'e20.10)') &
             i_bin, bin_r(i_bin), &
             (gs_avg(i_time, i_bin,i_spec),i_time = 1,n_time)
     enddo
  enddo
  
  ! output time, temperature and relative humidity data
  write(f_out_temp, '(a1,a19,a35)') '#', 'time(s)', 'temp(K) at each loop'
  write(f_out_rh, '(a1,a19,a35)') '#', 'time(s)', 'RH(1) at each loop'
  write(f_out_time, '(a1,a9,a35)') '#', 'time_num', 'time(s) at each loop'
  write(f_out_temp_avg, '(a1,a19,a20)') '#', 'time(s)', 'temp(K)'
  write(f_out_rh_avg, '(a1,a19,a20)') '#', 'time(s)', 'RH(1)'
  write(f_out_time_avg, '(a1,a9,a20)') '#', 'time_num', 'time(s)'
  do i_time = 1,n_time
     write(f_out_temp, '(e20.10,'//n_loop_str//'e20.10)') &
          time_avg(i_time), &
          (temp(i_loop, i_time), i_loop = 1,n_loop)
     write(f_out_rh, '(e20.10,'//n_loop_str//'e20.10)') &
          time_avg(i_time), &
          (rh(i_loop, i_time), i_loop = 1,n_loop)
     write(f_out_time, '(i10,'//n_loop_str//'e20.10)') &
          i_time, &
          (time(i_loop, i_time), i_loop = 1,n_loop)
     write(f_out_temp_avg, '(e20.10,e20.10)') &
          time_avg(i_time), temp_avg(i_time)
     write(f_out_rh_avg, '(e20.10,e20.10)') &
          time_avg(i_time), rh_avg(i_time)
     write(f_out_time_avg, '(i10,e20.10)') &
          i_time, time_avg(i_time)
  enddo
  
end program process_out

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
