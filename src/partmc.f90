! Copyright (C) 2007-2010 Nicole Riemer and Matthew West
! Licensed under the GNU General Public License version 2 or (at your
! option) any later version. See the file COPYING for details.

!> \file
!> The partmc program.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!> \mainpage PartMC Code Documentation
!!
!! \subpage input_format - Input file format description.
!!
!! \subpage output_format - Output file format description.
!!
!! \subpage module_diagram - Diagram of modules and dependencies.
!!
!! \subpage coding_style - Description of code conventions and style.
!!
!! \subpage publications - Publications about PartMC.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!> \page input_format Input File Format
!!
!! The input file format is plain text. See \ref spec_file_format for
!! a description of the file format.
!!
!! When running PartMC with the command <tt>partmc input.spec</tt> the
!! first line of the <tt>input.spec</tt> file must define the \c
!! run_type with:
!! <pre>
!! run_type &lt;type&gt;
!! </pre>
!! where <tt>&lt;type&gt;</tt> is one of \c particle, \c exact, or \c
!! sectional. This determines the type of run as well as the format of the
!! remainder of the spec file:
!!
!! \subpage input_format_particle "Particle-resolved simulation"
!!
!! \subpage input_format_exact "Exact (analytical) solution"
!!
!! \subpage input_format_sectional "Sectional model simulation"

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!> \page module_diagram Module Diagram
!!
!! \dotfile partmc_modules.gv

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!> \page coding_style Coding Style
!!
!! The code is mainly Fortran 90, with a few parts still clearly
!! showing their Fortran 77 heritage. A few Fortran 95 and Fortran
!! 2003 features are used (mainly the \c COMMAND_ARGUMENT_COUNT and \c
!! GET_COMMAND_ARGUMENT intrinsics). The code needs to be processed
!! with \c cpp or a compatible pre-processor.
!!
!! \section oo_fortran Object Oriented Fortran
!!
!! Extensive use is made of Fortran 90 derived types and pointers for
!! dynamic memory allocation of arrays inside derived types. Derived
!! types are named \c my_type_t and are generally defined in modules
!! named \c pmc_mod_my_type within files named \c my_type.f90. Each
!! derived type has allocation and deallocation functions \c
!! my_type_allocate() and \c my_type_deallocate(), where
!! appropriate. Almost all subroutines and function in each \c
!! my_type.f90 file have names of the form \c my_type_*() and take an
!! object of type \c my_type as the first argument on which to
!! operate.
!!
!! Module names are always the same as the name of the containing
!! file, but prefixed with \c pmc_. Thus the module \c
!! pmc_condense is contained in the file \c condense.f90.
!!
!! \section mem_manage Memory Management
!!
!! The memory allocation policy is that all functions must be called
!! with an already allocated structure. That is, if a subroutine
!! defines a variable of type \c my_type_t, then it must call \c
!! my_type_allocate() or \c my_type_allocate_size() on it before
!! passing it to any other subroutines or functions. The defining
!! subroutine is also responsible for calling \c my_type_deallocate()
!! on every variable it defines.
!!
!! Similarly, any subroutine that declares a pointer variable must
!! allocate it and any data it points to before passing it to other
!! subroutines or functions. If no specific length is known for an array
!! pointer then it should be allocated to zero size. Any subsequent
!! subroutines are free to deallocate and reallocate if they need to
!! change the size.
!!
!! This means that every subroutine (except for allocate and
!! deallocate routines) should contain matching \c
!! allocate()/deallocate() and
!! <tt>my_type_allocate()/my_type_deallocate()</tt> calls.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!> \page publications PartMC Publications
!!
!!   - N.&nbsp;Riemer, M.&nbsp;West, R.&nbsp;A.&nbsp;Zaveri, and
!!     R.&nbsp;C.&nbsp;Easter (2010) Estimating black carbon aging
!!     time-scales with a particle-resolved aerosol model, <i>Journal
!!     of Aerosol Science</i> 41(1), 143-158, DOI: <a
!!     href="http://dx.doi.org/10.1016/j.jaerosci.2009.08.009">10.1016/j.jaerosci.2009.08.009</a>
!!   - N.&nbsp;Riemer, M.&nbsp;West, R.&nbsp;A.&nbsp;Zaveri, and
!!     R.&nbsp;C.&nbsp;Easter (2009) Simulating the evolution of soot
!!     mixing state with a particle-resolved aerosol model, <i>Journal
!!     of Geophysical Research</i> 114(D09202), DOI: <a
!!     href="http://dx.doi.org/10.1029/2008JD011073">10.1029/2008JD011073</a>
!!   - R.&nbsp;McGraw, L.&nbsp;Leng, W.&nbsp;Zhu, N.&nbsp;Riemer, and
!!     M.&nbsp;West (2008) Aerosol dynamics using the quadrature
!!     method of moments: Comparing several quadrature schemes with
!!     particle-resolved simulation, <i>Journal of Physics: Conference
!!     Series</i> 125(012020), DOI: <a
!!     href="http://dx.doi.org/10.1088/1742-6596/125/1/012020">10.1088/1742-6596/125/1/012020</a>

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!> Top level driver.
program partmc

  use pmc_mpi
  use pmc_bin_grid
  use pmc_aero_state
  use pmc_aero_dist
  use pmc_aero_binned
  use pmc_coag_kernel
  use pmc_aero_data
  use pmc_aero_weight
  use pmc_env_data
  use pmc_env_state
  use pmc_run_part
  use pmc_run_exact
  use pmc_run_sect
  use pmc_spec_file
  use pmc_gas_data
  use pmc_gas_state
  use pmc_util
#ifdef PMC_USE_SUNDIALS
  use pmc_condense
#endif

  character(len=300) :: spec_name
  
  call pmc_mpi_init()

  if (pmc_mpi_rank() == 0) then
     ! only the root process accesses the commandline

     if (command_argument_count() /= 1) then
        call print_usage()
        call die_msg(739173192, "invalid commandline arguments")
     end if

     call get_command_argument(1, spec_name)
  end if

  call pmc_mpi_bcast_string(spec_name)
  call partmc_run(spec_name)

  call pmc_mpi_finalize()

contains

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Print the usage text to stderr.
  subroutine print_usage()

    write(*,*) 'Usage: partmc <spec-file>'

  end subroutine print_usage

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Do a PartMC run.
  subroutine partmc_run(spec_name)
    
    !> Spec filename.
    character(len=*), intent(in) :: spec_name

    type(spec_file_t) :: file
    character(len=100) :: run_type
    integer :: i

    ! check filename (must be "filename.spec")
    i = len_trim(spec_name)
    if (spec_name((i-4):i) /= '.spec') then
       call die_msg(710381938, "input filename must end in .spec")
    end if
    
    if (pmc_mpi_rank() == 0) then
       ! only the root process does I/O
       call spec_file_open(spec_name, file)
       call spec_file_read_string(file, 'run_type', run_type)
    end if
    
    call pmc_mpi_bcast_string(run_type)
    if (trim(run_type) == 'particle') then
       call partmc_part(file)
    elseif (trim(run_type) == 'exact') then
       call partmc_exact(file)
    elseif (trim(run_type) == 'sectional') then
       call partmc_sect(file)
    else
       call die_msg(719261940, "unknown run_type: " // trim(run_type))
    end if

  end subroutine partmc_run

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Run a Monte Carlo simulation.
  subroutine partmc_part(file)

    !> Spec file.
    type(spec_file_t), intent(inout) :: file

    type(gas_data_t) :: gas_data
    type(gas_state_t) :: gas_state
    type(gas_state_t) :: gas_state_init
    type(aero_data_t) :: aero_data
    type(aero_weight_t) :: aero_weight
    type(aero_dist_t) :: aero_dist_init
    type(aero_state_t) :: aero_state
    type(aero_state_t) :: aero_state_init
    type(env_data_t) :: env_data
    type(env_state_t) :: env_state
    type(env_state_t) :: env_state_init
    type(bin_grid_t) :: bin_grid
    type(run_part_opt_t) :: run_part_opt
    integer :: i_repeat
    integer :: rand_init
    character, allocatable :: buffer(:)
    integer :: buffer_size
    integer :: position
    logical :: do_restart, do_init_equilibriate
    character(len=PMC_MAX_FILENAME_LEN) :: restart_filename
    integer :: dummy_index, dummy_i_repeat
    real(kind=dp) :: dummy_time, dummy_del_t
    character(len=PMC_MAX_FILENAME_LEN) :: sub_filename
    type(spec_file_t) :: sub_file

    !> \page input_format_particle Input File Format: Particle-Resolved Simulation
    !!
    !! See \ref spec_file_format for the input file text format.
    !!
    !! A particle-resolved simulation spec file has the parameters:
    !! - \b run_type (string): must be \c particle
    !! - \b output_prefix (string): prefix of the output filenames
    !!   --- see \ref output_format for the full name format
    !! - \b n_repeat (integer): number of repeats
    !! - \b n_part (integer): number of computational particles to
    !!   simulate (actual number used will vary between <tt>n_part /
    !!   2</tt> and <tt>n_part * 2</tt> if \c allow_doubling and \c
    !!   allow_halving are \c yes)
    !! - \b restart (logical): whether to restart the simulation from
    !!   a saved output data file. If \c restart is \c yes, then the
    !!   following parameters must also be provided:
    !!   - \b restart_file (string): name of file from which to load
    !!     restart data, which must be a PartMC output NetCDF file
    !! - \b t_max (real, unit s): total simulation time
    !! - \b del_t (real, unit s): timestep size
    !! - \b t_output (real, unit s): the interval on which to
    !!   output data to disk (see \ref output_format)
    !! - \b t_progress (real, unit s): the interval on which to
    !!   write summary information to the screen while running
    !! - \subpage input_format_bin_grid --- only used for efficiency
    !!   gains during coagulation
    !! - \subpage input_format_aero_weight (only provide if
    !!   \c restart is \c no)
    !! - \b gas_data (string): name of file from which to read the
    !!   gas material data --- the file format should be
    !!   \subpage input_format_gas_data
    !! - \b gas_init (string): name of file from which to read the
    !!   initial gas state at the start of the simulation (only
    !!   provide option if \c restart is \c no) --- the file format
    !!   should be \subpage input_format_gas_state
    !! - \b aerosol_data (string): name of file from which to read the
    !!   aerosol material data --- the file format should be
    !!   \subpage input_format_aero_data
    !! - \b aerosol_init (string): filename containing the initial
    !!   aerosol state at the start of the simulation (only provide
    !!   option if \c restart is \c no) --- the file format should
    !!   be \subpage input_format_aero_dist
    !! - \subpage input_format_env_data
    !! - \subpage input_format_env_state
    !! - \b do_coagulation (logical): whether to perform particle
    !!   coagulation. If \c do_coagulation is \c yes, then the
    !!   following parameters must also be provided:
    !!   - \subpage input_format_coag_kernel
    !! - \b do_condensation (logical): whether to perform explicit
    !!   water condensation (requires SUNDIALS support to be compiled
    !!   in; cannot be used simultaneously with MOSAIC). If \c
    !!   do_condensation is \c yes, then the following parameters must
    !!   also be provided:
    !!   - \b do_init_equilibriate (logical): whether to equilibriate
    !!     the water content of each particle before starting the
    !!     simulation
    !! - \b do_mosaic (logical): whether to use the MOSAIC chemistry
    !!   code (requires support to be compiled in; cannot be used
    !!   simultaneously with condensation). If \c do_mosaic is \c
    !!   yes, then the following parameters must also be provided:
    !!   - \b do_optical (logical): whether to compute optical
    !!     properties of the aersol particles for the output files ---
    !!     see output_format_aero_state
    !! - \b do_nucleation (logical): whether to perform particle
    !!   nucleation. If \c do_nucleation is \c yes, then the following
    !!   parameters must also be provided:
    !!   - \subpage input_format_nucleate
    !! - \b rand_init (integer): if greater than zero then use as
    !!   the seed for the random number generator, or if zero then
    !!   generate a random seed for the random number generator ---
    !!   two simulations on the same machine with the same seed
    !!   (greater than 0) will produce identical output
    !! - \b allow_doubling (logical): if \c yes, then whenever the
    !!   number of simulated particles falls below <tt>n_part /
    !!   2</tt>, every particle is duplicated to give better
    !!   statistics
    !! - \b allow_halving (logical): if \c yes, then whenever the
    !!   number of simulated particles rises above <tt>n_part *
    !!   2</tt>, half of the particles are removed (chosen randomly)
    !!   to reduce the computational expense
    !! - \b record_removals (logical): whether to record information
    !!   about aerosol particles removed from the simulation --- see
    !!   \ref output_format_aero_removed
    !! - \b do_parallel (logical): whether to run in parallel mode
    !!   (requires MPI support to be compiled in). If \c do_parallel
    !!   is \c yes, then the following parameters must also be
    !!   provided:
    !!   - \subpage input_format_output
    !!   - \b mix_timescale (real, unit s): timescale on which to mix
    !!     aerosol particle information amongst processors in an
    !!     attempt to keep the aerosol state consistent (the mixing
    !!     rate is inverse to \c mix_timescale)
    !!   - \b gas_average (logical): whether to average the gas state
    !!     amongst processors each timestep, to ensure uniform gas
    !!     concentrations
    !!   - \b env_average (logical): whether to average the
    !!     environment state amongst processors each timestep, to
    !!     ensure a uniform environment
    !!   - \b coag_method (string): type of parallel coagulation ---
    !!     must be one of: \c local for only within-processor
    !!     coagulation; \c collect to transfer all particles to
    !!     processor 0 each timestep and coagulate there; \c central to
    !!     have processor 0 do all coagulation by requesting
    !!     individual particles as needed; or \c dist to have all
    !!     processors perform coagulation globally, requesting
    !!     particles from other processors as needed

    call gas_data_allocate(gas_data)
    call gas_state_allocate(gas_state)
    call gas_state_allocate(gas_state_init)
    call aero_data_allocate(aero_data)
    call aero_weight_allocate(aero_weight)
    call aero_dist_allocate(aero_dist_init)
    call aero_state_allocate(aero_state)
    call aero_state_allocate(aero_state_init)
    call env_data_allocate(env_data)
    call env_state_allocate(env_state)
    call env_state_allocate(env_state_init)
    call bin_grid_allocate(bin_grid)
    
    if (pmc_mpi_rank() == 0) then
       ! only the root process does I/O

       call spec_file_read_string(file, 'output_prefix', &
            run_part_opt%output_prefix)
       call spec_file_read_integer(file, 'n_repeat', run_part_opt%n_repeat)
       call spec_file_read_integer(file, 'n_part', run_part_opt%n_part_ideal)
       call spec_file_read_logical(file, 'restart', do_restart)
       if (do_restart) then
          call spec_file_read_string(file, 'restart_file', restart_filename)
       end if
       
       call spec_file_read_real(file, 't_max', run_part_opt%t_max)
       call spec_file_read_real(file, 'del_t', run_part_opt%del_t)
       call spec_file_read_real(file, 't_output', run_part_opt%t_output)
       call spec_file_read_real(file, 't_progress', run_part_opt%t_progress)

       call spec_file_read_bin_grid(file, bin_grid)

       if (.not. do_restart) then
          call spec_file_read_aero_weight(file, aero_weight)
       end if

       if (do_restart) then
          call input_state(restart_filename, bin_grid, aero_data, &
               aero_weight, aero_state_init, gas_data, gas_state_init, &
               env_state_init, dummy_index, dummy_time, dummy_del_t, &
               dummy_i_repeat, run_part_opt%uuid)
       end if

       call spec_file_read_string(file, 'gas_data', sub_filename)
       call spec_file_open(sub_filename, sub_file)
       call spec_file_read_gas_data(sub_file, gas_data)
       call spec_file_close(sub_file)

       if (.not. do_restart) then
          call spec_file_read_string(file, 'gas_init', sub_filename)
          call spec_file_open(sub_filename, sub_file)
          call spec_file_read_gas_state(sub_file, gas_data, &
               gas_state_init)
          call spec_file_close(sub_file)
       end if
       
       call spec_file_read_string(file, 'aerosol_data', sub_filename)
       call spec_file_open(sub_filename, sub_file)
       call spec_file_read_aero_data(sub_file, aero_data)
       call spec_file_close(sub_file)
       
       if (.not. do_restart) then
          call spec_file_read_string(file, 'aerosol_init', sub_filename)
          call spec_file_open(sub_filename, sub_file)
          call spec_file_read_aero_dist(sub_file, aero_data, aero_dist_init)
          call spec_file_close(sub_file)
       end if
       
       call spec_file_read_env_data(file, bin_grid, gas_data, aero_data, &
            env_data)
       call spec_file_read_env_state(file, env_state_init)
       
       call spec_file_read_logical(file, 'do_coagulation', &
            run_part_opt%do_coagulation)
       if (run_part_opt%do_coagulation) then
          call spec_file_read_coag_kernel_type(file, &
               run_part_opt%coag_kernel_type)
       else
          run_part_opt%coag_kernel_type = COAG_KERNEL_TYPE_INVALID
       end if

       call spec_file_read_logical(file, 'do_condensation', &
            run_part_opt%do_condensation)
#ifndef PMC_USE_SUNDIALS
       call assert_msg(121370218, &
            run_part_opt%do_condensation .eqv. .false., &
            "cannot use condensation, SUNDIALS support is not compiled in")
#endif
       if (run_part_opt%do_condensation) then
          call spec_file_read_logical(file, 'do_init_equilibriate', &
               do_init_equilibriate)
       else
          do_init_equilibriate = .false.
       end if

       call spec_file_read_logical(file, 'do_mosaic', run_part_opt%do_mosaic)
       if (run_part_opt%do_mosaic .and. (.not. mosaic_support())) then
          call spec_file_die_msg(230495365, file, &
               'cannot use MOSAIC, support is not compiled in')
       end if
       if (run_part_opt%do_mosaic .and. run_part_opt%do_condensation) then
          call spec_file_die_msg(599877804, file, &
               'cannot use MOSAIC and condensation simultaneously')
       end if
       if (run_part_opt%do_mosaic) then
          call spec_file_read_logical(file, 'do_optical', &
               run_part_opt%do_optical)
       else
          run_part_opt%do_optical = .false.
       end if

       call spec_file_read_logical(file, 'do_nucleation', &
            run_part_opt%do_nucleation)
       if (run_part_opt%do_nucleation) then
          call spec_file_read_nucleate_type(file, run_part_opt%nucleate_type)
       else
          run_part_opt%nucleate_type = NUCLEATE_TYPE_INVALID
       end if

       call spec_file_read_integer(file, 'rand_init', rand_init)
       call spec_file_read_logical(file, 'allow_doubling', &
            run_part_opt%allow_doubling)
       call spec_file_read_logical(file, 'allow_halving', &
            run_part_opt%allow_halving)
       call spec_file_read_logical(file, 'record_removals', &
            run_part_opt%record_removals)

       call spec_file_read_logical(file, 'do_parallel', &
            run_part_opt%do_parallel)
       if (run_part_opt%do_parallel) then
#ifndef PMC_USE_MPI
          call spec_file_die_msg(929006383, file, &
               'cannot use parallel mode, support is not compiled in')
#endif
          call spec_file_read_output_type(file, run_part_opt%output_type)
          call spec_file_read_real(file, 'mix_timescale', &
               run_part_opt%mix_timescale)
          call spec_file_read_logical(file, 'gas_average', &
               run_part_opt%gas_average)
          call spec_file_read_logical(file, 'env_average', &
               run_part_opt%env_average)
          call spec_file_read_string(file, 'coag_method', &
               run_part_opt%coag_method)
       else
          run_part_opt%output_type = OUTPUT_TYPE_SINGLE
          run_part_opt%mix_timescale = 0d0
          run_part_opt%gas_average = .false.
          run_part_opt%env_average = .false.
          run_part_opt%coag_method = "local"
       end if
       
       call spec_file_close(file)
    end if

    ! finished reading .spec data, now broadcast data

    if (.not. do_restart) then
       call uuid4_str(run_part_opt%uuid)
    end if

#ifdef PMC_USE_MPI
    if (pmc_mpi_rank() == 0) then
       ! root process determines size
       buffer_size = 0
       buffer_size = buffer_size &
            + pmc_mpi_pack_size_run_part_opt(run_part_opt)
       buffer_size = buffer_size + pmc_mpi_pack_size_bin_grid(bin_grid)
       buffer_size = buffer_size + pmc_mpi_pack_size_gas_data(gas_data)
       buffer_size = buffer_size + pmc_mpi_pack_size_gas_state(gas_state_init)
       buffer_size = buffer_size + pmc_mpi_pack_size_aero_data(aero_data)
       buffer_size = buffer_size + pmc_mpi_pack_size_aero_weight(aero_weight)
       buffer_size = buffer_size &
            + pmc_mpi_pack_size_aero_dist(aero_dist_init)
       buffer_size = buffer_size + pmc_mpi_pack_size_env_data(env_data)
       buffer_size = buffer_size + pmc_mpi_pack_size_env_state(env_state_init)
       buffer_size = buffer_size + pmc_mpi_pack_size_integer(rand_init)
       buffer_size = buffer_size + pmc_mpi_pack_size_logical(do_restart)
       buffer_size = buffer_size &
            + pmc_mpi_pack_size_logical(do_init_equilibriate)
       buffer_size = buffer_size &
            + pmc_mpi_pack_size_aero_state(aero_state_init)
    end if

    ! tell everyone the size and allocate buffer space
    call pmc_mpi_bcast_integer(buffer_size)
    allocate(buffer(buffer_size))

    if (pmc_mpi_rank() == 0) then
       ! root process packs data
       position = 0
       call pmc_mpi_pack_run_part_opt(buffer, position, run_part_opt)
       call pmc_mpi_pack_bin_grid(buffer, position, bin_grid)
       call pmc_mpi_pack_gas_data(buffer, position, gas_data)
       call pmc_mpi_pack_gas_state(buffer, position, gas_state_init)
       call pmc_mpi_pack_aero_data(buffer, position, aero_data)
       call pmc_mpi_pack_aero_weight(buffer, position, aero_weight)
       call pmc_mpi_pack_aero_dist(buffer, position, aero_dist_init)
       call pmc_mpi_pack_env_data(buffer, position, env_data)
       call pmc_mpi_pack_env_state(buffer, position, env_state_init)
       call pmc_mpi_pack_integer(buffer, position, rand_init)
       call pmc_mpi_pack_logical(buffer, position, do_restart)
       call pmc_mpi_pack_logical(buffer, position, do_init_equilibriate)
       call pmc_mpi_pack_aero_state(buffer, position, aero_state_init)
       call assert(181905491, position == buffer_size)
    end if

    ! broadcast data to everyone
    call pmc_mpi_bcast_packed(buffer)

    if (pmc_mpi_rank() /= 0) then
       ! non-root processes unpack data
       position = 0
       call pmc_mpi_unpack_run_part_opt(buffer, position, run_part_opt)
       call pmc_mpi_unpack_bin_grid(buffer, position, bin_grid)
       call pmc_mpi_unpack_gas_data(buffer, position, gas_data)
       call pmc_mpi_unpack_gas_state(buffer, position, gas_state_init)
       call pmc_mpi_unpack_aero_data(buffer, position, aero_data)
       call pmc_mpi_unpack_aero_weight(buffer, position, aero_weight)
       call pmc_mpi_unpack_aero_dist(buffer, position, aero_dist_init)
       call pmc_mpi_unpack_env_data(buffer, position, env_data)
       call pmc_mpi_unpack_env_state(buffer, position, env_state_init)
       call pmc_mpi_unpack_integer(buffer, position, rand_init)
       call pmc_mpi_unpack_logical(buffer, position, do_restart)
       call pmc_mpi_unpack_logical(buffer, position, do_init_equilibriate)
       call pmc_mpi_unpack_aero_state(buffer, position, aero_state_init)
       call assert(143770146, position == buffer_size)
    end if

    ! free the buffer
    deallocate(buffer)
#endif

    call pmc_srand(rand_init + pmc_mpi_rank())

    call gas_state_deallocate(gas_state)
    call gas_state_allocate_size(gas_state, gas_data%n_spec)
    call cpu_time(run_part_opt%t_wall_start)
    
    do i_repeat = 1,run_part_opt%n_repeat
       run_part_opt%i_repeat = i_repeat
       
       call gas_state_copy(gas_state_init, gas_state)
       if (do_restart) then
          call aero_state_copy(aero_state_init, aero_state)
       else
          call aero_state_deallocate(aero_state)
          call aero_state_allocate_size(aero_state, bin_grid%n_bin, &
               aero_data%n_spec)
          aero_state%comp_vol = real(run_part_opt%n_part_ideal, kind=dp) / &
               aero_dist_weighted_num_conc(aero_dist_init, aero_weight)
          call aero_state_add_aero_dist_sample(aero_state, bin_grid, &
               aero_data, aero_weight, aero_dist_init, 1d0, 0d0)
       end if
       call env_state_copy(env_state_init, env_state)
       call env_data_init_state(env_data, env_state, &
            env_state_init%elapsed_time)

#ifdef PMC_USE_SUNDIALS
       if (do_init_equilibriate) then
          call condense_equilib_particles(bin_grid, env_state, aero_data, &
               aero_weight, aero_state)
       end if
#endif
       
       call run_part(bin_grid, env_data, env_state, aero_data, aero_weight, &
            aero_state, gas_data, gas_state, run_part_opt)

    end do

    call gas_data_deallocate(gas_data)
    call gas_state_deallocate(gas_state)
    call gas_state_deallocate(gas_state_init)
    call aero_data_deallocate(aero_data)
    call aero_weight_deallocate(aero_weight)
    call aero_dist_deallocate(aero_dist_init)
    call aero_state_deallocate(aero_state)
    call aero_state_deallocate(aero_state_init)
    call env_data_deallocate(env_data)
    call env_state_deallocate(env_state)
    call env_state_deallocate(env_state_init)
    call bin_grid_deallocate(bin_grid)

  end subroutine partmc_part

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Run an exact solution simulation.
  subroutine partmc_exact(file)

    !> Spec file.
    type(spec_file_t), intent(inout) :: file

    character(len=100) :: soln_name
    type(aero_data_t) :: aero_data
    type(env_data_t) :: env_data
    type(env_state_t) :: env_state
    type(aero_dist_t) :: aero_dist_init
    type(run_exact_opt_t) :: run_exact_opt
    type(bin_grid_t) :: bin_grid
    type(gas_data_t) :: gas_data
    character(len=PMC_MAX_FILENAME_LEN) :: sub_filename
    type(spec_file_t) :: sub_file

    !> \page input_format_exact Exact (Analytical) Solution
    !!
    !! The coagulation kernel and initial distribution must be matched
    !! for an exact solution to exist. The valid choices are:
    !!
    !! <table>
    !! <tr><th>Coagulation kernel</th>
    !!     <th>Initial aerosol distribution</th></tr>
    !! <tr><td>Additive</td>
    !!     <td>Single exponential mode</td></tr>
    !! <tr><td>Constant</td>
    !!     <td>Single exponential mode</td></tr>
    !! <tr><td>Zero</td>
    !!     <td>Anything</td></tr>
    !! </table>
    !!
    !! See \ref spec_file_format for the input file text format.
    !!
    !! An exact (analytical) simulation spec file has the parameters:
    !! - \b run_type (string): must be \c exact
    !! - \b output_prefix (string): prefix of the output filenames ---
    !!   the filenames will be of the form \c PREFIX_SSSSSSSS.nc where
    !!   \c SSSSSSSS is is the eight-digit output index (starting at 1
    !!   and incremented each time the state is output)
    !! - \b t_max (real, unit s): total simulation time
    !! - \b t_output (real, unit s): the interval on which to output
    !!   data to disk and to print progress information to the screen
    !!   (see \ref output_format)
    !! - \subpage input_format_bin_grid
    !! - \b gas_data (string): name of file from which to read the
    !!   gas material data --- the file format should be
    !!   \subpage input_format_gas_data
    !! - \b aerosol_data (string): name of file from which to read the
    !!   aerosol material data --- the file format should be
    !!   \subpage input_format_aero_data
    !! - \b aerosol_init (string): filename containing the initial
    !!   aerosol state at the start of the simulation --- the file
    !!   format should be \subpage input_format_aero_dist
    !! - \subpage input_format_env_data
    !! - \subpage input_format_env_state
    !! - \b do_coagulation (logical): whether to perform particle
    !!   coagulation.  If \c do_coagulation is \c yes, then the
    !!   following parameters must also be provided:
    !!   - \subpage input_format_coag_kernel
    !!
    !! Example:
    !! <pre>
    !! run_type exact                  # exact solution
    !! output_prefix additive_exact    # prefix of output files
    !! 
    !! t_max 600                       # total simulation time (s)
    !! t_output 60                     # output interval (0 disables) (s)
    !! 
    !! n_bin 160                       # number of bins
    !! d_min 1e-8                      # minimum diameter (m)
    !! d_max 1e-3                      # maximum diameter (m)
    !! 
    !! gas_data gas_data.dat           # file containing gas data
    !!
    !! aerosol_data aero_data.dat      # file containing aerosol data
    !! aerosol_init aero_init_dist.dat # aerosol initial condition file
    !! 
    !! temp_profile temp.dat           # temperature profile file
    !! height_profile height.dat       # height profile file
    !! gas_emissions gas_emit.dat      # gas emissions file
    !! gas_background gas_back.dat     # background gas mixing ratios file
    !! aero_emissions aero_emit.dat    # aerosol emissions file
    !! aero_background aero_back.dat   # aerosol background file
    !! 
    !! rel_humidity 0.999              # initial relative humidity (1)
    !! pressure 1e5                    # initial pressure (Pa)
    !! latitude 0                      # latitude (degrees, -90 to 90)
    !! longitude 0                     # longitude (degrees, -180 to 180)
    !! altitude 0                      # altitude (m)
    !! start_time 0                    # start time (s since 00:00 UTC)
    !! start_day 1                     # start day of year (UTC)
    !!
    !! do_coagulation yes              # whether to do coagulation (yes/no)
    !! kernel additive                 # Additive coagulation kernel
    !! </pre>

    ! only serial code here
    if (pmc_mpi_rank() /= 0) then
       return
    end if
    
    call bin_grid_allocate(bin_grid)
    call gas_data_allocate(gas_data)
    call aero_data_allocate(aero_data)
    call env_data_allocate(env_data)
    call env_state_allocate(env_state)
    call aero_dist_allocate(aero_dist_init)

    call spec_file_read_string(file, 'output_prefix', run_exact_opt%prefix)

    call spec_file_read_real(file, 't_max', run_exact_opt%t_max)
    call spec_file_read_real(file, 't_output', run_exact_opt%t_output)

    call spec_file_read_bin_grid(file, bin_grid)

    call spec_file_read_string(file, 'gas_data', sub_filename)
    call spec_file_open(sub_filename, sub_file)
    call spec_file_read_gas_data(sub_file, gas_data)
    call spec_file_close(sub_file)

    call spec_file_read_string(file, 'aerosol_data', sub_filename)
    call spec_file_open(sub_filename, sub_file)
    call spec_file_read_aero_data(sub_file, aero_data)
    call spec_file_close(sub_file)

    call spec_file_read_string(file, 'aerosol_init', sub_filename)
    call spec_file_open(sub_filename, sub_file)
    call spec_file_read_aero_dist(sub_file, aero_data, aero_dist_init)
    call spec_file_close(sub_file)

    call spec_file_read_env_data(file, bin_grid, gas_data, aero_data, &
         env_data)
    call spec_file_read_env_state(file, env_state)

    call spec_file_read_logical(file, 'do_coagulation', &
         run_exact_opt%do_coagulation)
    if (run_exact_opt%do_coagulation) then
       call spec_file_read_coag_kernel_type(file, &
            run_exact_opt%coag_kernel_type)
    else
       run_exact_opt%coag_kernel_type = COAG_KERNEL_TYPE_INVALID
    end if
    
    call spec_file_close(file)

    ! finished reading .spec data, now do the run

    call uuid4_str(run_exact_opt%uuid)

    call env_data_init_state(env_data, env_state, 0d0)

    call run_exact(bin_grid, env_data, env_state, aero_data, &
         aero_dist_init, run_exact_opt)

    call aero_data_deallocate(aero_data)
    call env_data_deallocate(env_data)
    call env_state_deallocate(env_state)
    call bin_grid_deallocate(bin_grid)
    call gas_data_deallocate(gas_data)
    call aero_dist_deallocate(aero_dist_init)
    
  end subroutine partmc_exact

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Run a sectional code simulation.
  subroutine partmc_sect(file)

    !> Spec file.
    type(spec_file_t), intent(inout) :: file

    type(run_sect_opt_t) :: run_sect_opt
    type(aero_data_t) :: aero_data
    type(aero_dist_t) :: aero_dist_init
    type(aero_state_t) :: aero_init
    type(env_data_t) :: env_data
    type(env_state_t) :: env_state
    type(bin_grid_t) :: bin_grid
    type(gas_data_t) :: gas_data
    character(len=PMC_MAX_FILENAME_LEN) :: sub_filename
    type(spec_file_t) :: sub_file

    !> \page input_format_sectional Sectional Model Simulation
    !!
    !! See \ref spec_file_format for the input file text format.
    !!
    !! A sectional simulation spec file has the parameters:
    !! - \b run_type (string): must be \c sectional
    !! - \b output_prefix (string): prefix of the output filenames ---
    !!   the filenames will be of the form \c PREFIX_SSSSSSSS.nc where
    !!   \c SSSSSSSS is is the eight-digit output index (starting at 1
    !!   and incremented each time the state is output)
    !! - \b del_t (real, unit s): timestep size
    !! - \b t_output (real, unit s): the interval on which to
    !!   output data to disk (see \ref output_format)
    !! - \b t_progress (real, unit s): the interval on which to
    !!   write summary information to the screen while running
    !! - \subpage input_format_bin_grid
    !! - \b gas_data (string): name of file from which to read the
    !!   gas material data --- the file format should be
    !!   \subpage input_format_gas_data
    !! - \b aerosol_data (string): name of file from which to read the
    !!   aerosol material data --- the file format should be
    !!   \subpage input_format_aero_data
    !! - \b aerosol_init (string): filename containing the initial
    !!   aerosol state at the start of the simulation --- the file
    !!   format should be \subpage input_format_aero_dist
    !! - \subpage input_format_env_data
    !! - \subpage input_format_env_state
    !! - \b do_coagulation (logical): whether to perform particle
    !!   coagulation.  If \c do_coagulation is \c yes, then the
    !!   following parameters must also be provided:
    !!   - \subpage input_format_coag_kernel
    !!
    !! Example:
    !! <pre>
    !! run_type sectional              # sectional code run
    !! output_prefix brown_sect        # prefix of output files
    !! 
    !! t_max 86400                     # total simulation time (s)
    !! del_t 60                        # timestep (s)
    !! t_output 3600                   # output interval (0 disables) (s)
    !! t_progress 600                  # progress printing interval (0 disables) (s)
    !! 
    !! n_bin 220                       # number of bins
    !! d_min 1e-10                     # minimum diameter (m)
    !! d_max 1e-4                      # maximum diameter (m)
    !! 
    !! gas_data gas_data.dat           # file containing gas data
    !! aerosol_data aero_data.dat      # file containing aerosol data
    !! aerosol_init aero_init_dist.dat # initial aerosol distribution
    !! 
    !! temp_profile temp.dat           # temperature profile file
    !! height_profile height.dat       # height profile file
    !! gas_emissions gas_emit.dat      # gas emissions file
    !! gas_background gas_back.dat     # background gas mixing ratios file
    !! aero_emissions aero_emit.dat    # aerosol emissions file
    !! aero_background aero_back.dat   # aerosol background file
    !! 
    !! rel_humidity 0.999              # initial relative humidity (1)
    !! pressure 1e5                    # initial pressure (Pa)
    !! latitude 0                      # latitude (degrees_north, -90 to 90)
    !! longitude 0                     # longitude (degrees_east, -180 to 180)
    !! altitude 0                      # altitude (m)
    !! start_time 0                    # start time (s since 00:00 UTC)
    !! start_day 1                     # start day of year (UTC)
    !! 
    !! do_coagulation yes              # whether to do coagulation (yes/no)
    !! kernel brown                    # coagulation kernel
    !! </pre>

    ! only serial code here
    if (pmc_mpi_rank() /= 0) then
       return
    end if
    
    call aero_data_allocate(aero_data)
    call aero_dist_allocate(aero_dist_init)
    call env_state_allocate(env_state)
    call env_data_allocate(env_data)
    call bin_grid_allocate(bin_grid)
    call gas_data_allocate(gas_data)

    call spec_file_read_string(file, 'output_prefix', run_sect_opt%prefix)

    call spec_file_read_real(file, 't_max', run_sect_opt%t_max)
    call spec_file_read_real(file, 'del_t', run_sect_opt%del_t)
    call spec_file_read_real(file, 't_output', run_sect_opt%t_output)
    call spec_file_read_real(file, 't_progress', run_sect_opt%t_progress)

    call spec_file_read_bin_grid(file, bin_grid)

    call spec_file_read_string(file, 'gas_data', sub_filename)
    call spec_file_open(sub_filename, sub_file)
    call spec_file_read_gas_data(sub_file, gas_data)
    call spec_file_close(sub_file)
    
    call spec_file_read_string(file, 'aerosol_data', sub_filename)
    call spec_file_open(sub_filename, sub_file)
    call spec_file_read_aero_data(sub_file, aero_data)
    call spec_file_close(sub_file)

    call spec_file_read_string(file, 'aerosol_init', sub_filename)
    call spec_file_open(sub_filename, sub_file)
    call spec_file_read_aero_dist(sub_file, aero_data, aero_dist_init)
    call spec_file_close(sub_file)

    call spec_file_read_env_data(file, bin_grid, gas_data, aero_data, &
         env_data)
    call spec_file_read_env_state(file, env_state)

    call spec_file_read_logical(file, 'do_coagulation', &
         run_sect_opt%do_coagulation)
    if (run_sect_opt%do_coagulation) then
       call spec_file_read_coag_kernel_type(file, &
            run_sect_opt%coag_kernel_type)
    else
       run_sect_opt%coag_kernel_type = COAG_KERNEL_TYPE_INVALID
    end if
    
    call spec_file_close(file)

    ! finished reading .spec data, now do the run

    call uuid4_str(run_sect_opt%uuid)

    call env_data_init_state(env_data, env_state, 0d0)

    call run_sect(bin_grid, gas_data, aero_data, aero_dist_init, env_data, &
         env_state, run_sect_opt)

    call aero_data_deallocate(aero_data)
    call aero_dist_deallocate(aero_dist_init)
    call env_state_deallocate(env_state)
    call env_data_deallocate(env_data)
    call bin_grid_deallocate(bin_grid)
    call gas_data_deallocate(gas_data)
    
  end subroutine partmc_sect

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

end program partmc
