    !------------------------------------------------------------------------------
    !        IST/MARETEC, Water Modelling Group, Mohid modelling system
    !------------------------------------------------------------------------------
    !
    ! TITLE         : Mohid Model
    ! PROJECT       : Mohid Lagrangian Tracer
    ! MODULE        : source_emitter
    ! URL           : http://www.mohid.com
    ! AFFILIATION   : IST/MARETEC, Marine Modelling Group
    ! DATE          : April 2018
    ! REVISION      : Canelas 0.1
    !> @author
    !> Ricardo Birjukovs Canelas
    !
    ! DESCRIPTION:
    !> Module that defines an emitter class and related methods. This module is
    !> responsible for building a potential tracer list based on the availble
    !> sources and calling their initializers.
    !------------------------------------------------------------------------------

    module source_emitter

    use commom_modules
    use source_identity
    use tracers

    implicit none
    private

    type :: emitter_t
        integer :: emitted
        integer :: emittable
    contains
    procedure :: initialize
    procedure :: alloctracers
    procedure :: initracers
    !procedure :: activecheck
    end type

    type(emitter_t) ::  Emitter

    !Public access vars
    public :: Emitter

    contains

    !---------------------------------------------------------------------------
    !> @Ricardo Birjukovs Canelas - MARETEC
    ! Routine Author Name and Affiliation.
    !
    !> @brief
    !> method that calls the tracer initialization from the emmiter object
    !
    !> @param[in] self, src
    !---------------------------------------------------------------------------
    subroutine initracers(self, srcs)
    implicit none
    class(emitter_t), intent(inout) :: self
    class(source_class), dimension(:), intent(inout) :: srcs
    integer num_emiss, i, j, k, p
    type(string) :: outext, temp(4)
    integer :: sizem

    p=0
    do i=1, size(srcs)
        num_emiss = srcs(i)%stencil%total_np/size(srcs(i)%stencil%ptlist)
        do j=1, num_emiss
            do k=1, size(srcs(i)%stencil%ptlist)
                p=p+1
                call Tracer(p)%initialize(p, srcs(i)%par%id, SimTime, srcs(i)%stencil%ptlist(k))
            enddo
        enddo
    enddo
    sizem = sizeof(Tracer)
    call SimMemory%addtracer(sizem)

    return
    end subroutine

    !---------------------------------------------------------------------------
    !> @Ricardo Birjukovs Canelas - MARETEC
    ! Routine Author Name and Affiliation.
    !
    !> @brief
    !> method that initializes an emmiter class object. Computes the total emittable
    !> particles this emmiter will allocate and sets other variables
    !
    !> @param[in] self, src
    !---------------------------------------------------------------------------
    subroutine alloctracers(self, srcs)
    implicit none
    class(emitter_t), intent(inout) :: self
    class(source_class), dimension(:), intent(inout) :: srcs
    integer err
    type(string) :: outext, temp

    if (self%emittable .le. 0) then
        outext='Emitter::alloctracers : No Tracers will be simulated, stoping'
        call ToLog(outext)
        stop
    else
        allocate(Tracer(self%emittable), stat=err)
        if(err/=0)then
            outext='Emitter::alloctracers : Cannot allocate Tracers, stoping'
            call ToLog(outext)
            stop
        endif
    endif

    temp = size(Tracer)
    outext='Allocated '// temp // ' Tracers.'
    call ToLog(outext)
    !receiving Sources as argument so latter we can differentiate between tracer types

    end subroutine

    !---------------------------------------------------------------------------
    !> @Ricardo Birjukovs Canelas - MARETEC
    ! Routine Author Name and Affiliation.
    !
    !> @brief
    !> method that initializes an emmiter class object. Computes the total emittable
    !> particles this emmiter will allocate and sets other variables
    !
    !> @param[in] self, src
    !---------------------------------------------------------------------------
    subroutine initialize(self, srcs)
    implicit none
    class(emitter_t), intent(inout) :: self
    class(source_class), dimension(:), intent(inout) :: srcs
    integer :: i
    integer :: sizem

    self%emitted = 0
    self%emittable = 0
    do i=1, size(srcs)
        call setotalnp(srcs(i)) !finding the total tracers this Source will pass the emmiter
        self%emittable = self%emittable + srcs(i)%stencil%total_np
        !print*, srcs(i)%stencil%total_np
    end do
    sizem = sizeof(self)
    call SimMemory%addsource(sizem)

    !allocating and initializing the tracers by the emitter, for all sources
    call self%alloctracers(srcs)
    call self%initracers(srcs)

    end subroutine

    !---------------------------------------------------------------------------
    !> @Ricardo Birjukovs Canelas - MARETEC
    ! Routine Author Name and Affiliation.
    !
    !> @brief
    !> private routine that returns the total number of tracers an input
    !> source will potentially create
    !
    !> @param[in] src
    !---------------------------------------------------------------------------
    subroutine setotalnp(src)
    implicit none
    class(source_class), intent(inout) :: src
    !> \f${NP}_{total}^{source-i}=(T_{end}^{source-i}-T_{start}^{source-i})*{Rate}^{source-i}*{NP}_{emission}^{source-i}\f$
    src%stencil%total_np=(src%par%stoptime-src%par%startime)*src%par%emitting_rate*src%stencil%np
    end subroutine

    end module source_emitter