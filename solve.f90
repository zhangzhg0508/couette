MODULE solve
implicit none

contains

SUBROUTINE solve_ux(uo, u, u_nl, t, ux)
use parameters
use variables
use ic_bc
implicit none
double precision, intent(in) :: t
double precision, intent(in) :: u(0:nx,0:nz), u_nl(0:nx,0:nz)
type (mat_comp), intent(in) :: ux
double precision, intent(inout) :: uo(0:nx,0:nz)
double precision :: ux_rhs(nx1)
integer :: j, k

call u_BCS(uo, t)

do k = 1, nz1
   ux_rhs(:) = u(1:nx1,k) + u_nl(1:nx1,k)

   ux_rhs(1) = ux_rhs(1) + (0.5d0 * rxx * uo(0,k)) - &
               (((1d0 - eta) * rx) / (4d0 * s(1))) * uo(0,k)
   ux_rhs(nx1) = ux_rhs(nx1) + (0.5d0 * rxx * uo(nx,k)) + &
               (((1d0 - eta) * rx) / (4d0 * s(nx1))) * uo(nx,k)

   call thomas(xlb, nx1, ux%up, ux%di, ux%lo, ux_rhs)

   uo(1:nx1,k) = ux_rhs(:)
end do

if (tau /= 1) then
   do k = 0, nz, nz
      ux_rhs(:) = u(1:nx1,k) + u_nl(1:nx1,k)

      ux_rhs(1) = ux_rhs(1) + (0.5d0 * rxx * uo(0,k)) - &
                  (((1d0 - eta) * rx) / (4d0 * s(1))) * uo(0,k)
      ux_rhs(nx1) = ux_rhs(nx1) + (0.5d0 * rxx * uo(nx,k)) + &
                  (((1d0 - eta) * rx) / (4d0 * s(nx1))) * uo(nx,k)

      call thomas(xlb, nx1, ux%up, ux%di, ux%lo, ux_rhs)

      uo(1:nx1,k) = ux_rhs(:)
   end do
end if

return
END SUBROUTINE solve_ux

SUBROUTINE solve_Zx(zo, zn, z_nl, po, t, zx)
use parameters
use variables
use ic_bc
implicit none
double precision, intent(in) :: t
double precision, intent(in) :: zn(0:nx,0:nz), po(0:nx,0:nz), &
                                z_nl(0:nx,0:nz)
type (mat_comp), intent(in) :: zx
double precision, intent(inout) :: zo(0:nx,0:nz)
double precision :: zx_rhs(nx1)
integer :: j, k

call z_BCS(zo, po, t)

do k = 1, nz1
   zx_rhs(:) = zn(1:nx1,k) + z_nl(1:nx1,k)

   zx_rhs(1) = zx_rhs(1) + (0.5d0 * rxx * zo(0,k)) - &
               (((1d0 - eta) * rx) / (4d0 * s(1))) * zo(0,k)
   zx_rhs(nx1) = zx_rhs(nx1) + (0.5d0 * rxx * zo(nx,k)) + &
               (((1d0 - eta) * rx) / (4d0 * s(nx1))) * zo(nx,k)

   call thomas(xlb, nx1, zx%up, zx%di, zx%lo, zx_rhs)

   zo(1:nx1,k) = zx_rhs(:)
end do

return
END SUBROUTINE solve_Zx

SUBROUTINE solve_uz(uo, u, t, uz)
use parameters
use variables
use ic_bc
implicit none
double precision, intent(in) :: t
double precision, intent(in) :: uo(0:nx,0:nz)
type (uz_mat_comp), intent(in) :: uz
double precision, intent(inout) :: u(0:nx,0:nz)
double precision :: uz_rhs(0:nz), uz_rhs_t1(nz1), &
                    up(nz-2), di(nz1), lo(2:nz1)
integer :: j, k

call u_BCS(u, t)

if (tau == 1) then
   up(:) = uz%up(1:nz-2)
   di(:) = uz%di(1:nz1)
   lo(:) = uz%lo(2:nz1)

   do j = 1, nx1
      uz_rhs_t1(:) = uo(j,1:nz1)

      uz_rhs_t1(1) = uz_rhs_t1(1) + 0.5d0 * rzz * u(j,0)
      uz_rhs_t1(nz1) = uz_rhs_t1(nz1) + 0.5d0 * rzz * u(j,nz)

      call thomas(zlb+1, nz1, up, di, lo, uz_rhs_t1)

      u(j,1:nz1) = uz_rhs_t1(:)
   end do
else
   do j = 1, nx1
      uz_rhs(:) = uo(j,:)

      call thomas(zlb, nz, uz%up, uz%di, uz%lo, uz_rhs)

      u(j,:) = uz_rhs(:)
   end do
end if

return
END SUBROUTINE solve_uz

SUBROUTINE solve_Zz(zo, po, zn, t, zz)
use parameters
use variables
use ic_bc
implicit none
double precision, intent(in) :: t
double precision, intent(in) :: zo(0:nx,0:nz), po(0:nx,0:nz)
type (zz_mat_comp), intent(in) :: zz
double precision, intent(inout) :: zn(0:nx,0:nz)
double precision :: Zz_rhs(nz1)
integer :: j, k

call z_BCS(zn, po, t)

do j = 1, nx1
   Zz_rhs(:) = zo(j,1:nz1)

   Zz_rhs(1) = Zz_rhs(1) + 0.5d0 * rzz * zn(j,0)
   Zz_rhs(nz1) = Zz_rhs(nz1) + 0.5d0 * rzz * zn(j,nz)

   call thomas(zlb+1, nz1, zz%up, zz%di, zz%lo, Zz_rhs)

   zn(j,1:nz1) = Zz_rhs(:)
end do

return
END SUBROUTINE solve_Zz

SUBROUTINE thomas (lb, m, up, di, lo, r)
implicit none
integer :: j
integer, intent(in) :: m, lb
double precision, intent(in) :: up(lb:m-1), di(lb:m), lo(lb+1:m)
double precision, intent(inout) :: r(lb:m)
double precision :: dnew(lb:m), aa = 0d0

dnew = di
do j = lb+1, m
   aa = -lo(j) / dnew(j-1)
   dnew(j) = dnew(j) + aa * up(j-1)
   r(j) = r(j) + aa * r(j-1)
end do

r(m) = r(m) / dnew(m)

do j = m-1, lb, -1
   r(j) = (r(j) - up(j) * r(j+1)) / dnew(j)
end do

return
END SUBROUTINE thomas

END MODULE solve