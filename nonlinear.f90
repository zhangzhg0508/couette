MODULE nonlinear
implicit none

contains

SUBROUTINE get_nlin_ux(uo, uo2, po, po2, bo, bo2, u_nl_n)
use parameters
use variables
use derivs
use ic_bc 
implicit none
double precision, intent(in) :: uo(0:nx,0:nz), uo2(0:nx,0:nz), &
                                po(0:nx,0:nz), po2(0:nx,0:nz), &
                                bo(0:nx,0:nz), bo2(0:nx,0:nz)
double precision, intent(out) :: u_nl_n(0:nx,0:nz) 
                 
type (deriv) :: du, du2, dp, dp2, db, db2
integer :: j, k  
                 
call deriv_x(uo, du%x)
call deriv_x(uo2, du2%x)
call deriv_z(uo, du%z)
call deriv_z(uo2, du2%z)
call deriv_x(po, dp%x)
call deriv_x(po2, dp2%x)
call deriv_z(po, dp%z)
call deriv_z(po2, dp2%z)
call deriv_z(bo, db%z)
call deriv_z(bo2, db2%z)

do k = 1, nz1
   u_nl_n(1:nx1,k) = (-rx / (8d0 * s(1:nx1) * delz)) * &
                     (3d0 * (dp%x(1:nx1,k) * du%z(1:nx1,k) - &
                     dp%z(1:nx1,k) * du%x(1:nx1,k)) - &
                     (dp2%x(1:nx1,k) * du2%z(1:nx1,k) - &
                     dp2%z(1:nx1,k) * du2%x(1:nx1,k))) + &
                     ((1d0 - eta) * rz / (4d0 * s(1:nx1)**2)) * &
                     (3d0 * uo(1:nx1,k) * dp%z(1:nx1,k) - &
                     uo2(1:nx1,k) * dp2%z(1:nx1,k)) + &
                     0.25d0 * rz * Q * (3d0 * db%z(1:nx1,k) - &
                     db2%z(1:nx1,k))
end do

if (tau /= 1) then
   u_nl_n(1:nx1,0) = (-rx / (8d0 * s(1:nx1) * delz)) * &
                     (-3d0 * dp%z(1:nx1,0) * du%x(1:nx1,0) + &
                     dp2%z(1:nx1,0) * du2%x(1:nx1,0)) + &
                     ((1d0 - eta) * rz / (4d0 * s(1:nx1)**2)) * &
                     (3d0 * uo(1:nx1,0) * dp%z(1:nx1,0) - &
                     uo2(1:nx1,0) * dp2%z(1:nx1,0)) + &
                     0.25d0 * rz * Q * (3d0 * db%z(1:nx1,0) - &
                     db2%z(1:nx1,0))

   u_nl_n(1:nx1,nz) = (-rx / (8d0 * s(1:nx1) * delz)) * &
                      (-3d0 * dp%z(1:nx1,nz) * du%x(1:nx1,nz) + &
                      dp2%z(1:nx1,nz) * du2%x(1:nx1,nz)) + &
                      ((1d0 - eta) * rz / (4d0 * s(1:nx1)**2)) * &
                      (3d0 * uo(1:nx1,nz) * dp%z(1:nx1,nz) - &
                      uo2(1:nx1,nz) * dp2%z(1:nx1,nz)) + &
                      0.25d0 * rz * Q * (3d0 * db%z(1:nx1,nz) - &
                      db2%z(1:nx1,nz))
end if

return
END SUBROUTINE get_nlin_ux

SUBROUTINE get_nlin_Zx(t, uo, uo2, po, po2, zo, zo2, jo, jo2, z_nl_n)
use parameters
use variables
use derivs
use ic_bc
implicit none
double precision, intent(in) :: t, uo(0:nx,0:nz), uo2(0:nx,0:nz), &
                                po(0:nx,0:nz), po2(0:nx,0:nz), &
                                zo(0:nx,0:nz), zo2(0:nx,0:nz), &
                                jo(0:nx,0:nz), jo2(0:nx,0:nz)
double precision, intent(out) :: z_nl_n(0:nx,0:nz)
type (deriv) :: du, du2, dp, dp2, dz, dz_2, dj, dj2
integer :: j, k

call deriv_z(uo, du%z)
call deriv_z(uo2, du2%z)
call deriv_x(po, dp%x)
call deriv_x(po2, dp2%x)
call deriv_z(po, dp%z)
call deriv_z(po2, dp2%z)
call deriv_x(zo, dz%x)
call deriv_x(zo2, dz_2%x)
call deriv_z(zo, dz%z)
call deriv_z(zo2, dz_2%z)
call deriv_z(jo, dj%z)
call deriv_z(jo2, dj2%z)

do k = 1, nz1
   z_nl_n(1:nx1,k) = (((1d0 - eta) * rz) / (2d0 * s(1:nx1))) * &
                     (3d0 * uo(1:nx1,k) * du%z(1:nx1,k) - &
                     uo2(1:nx1,k) * du2%z(1:nx1,k)) - &
                     ((1d0 - eta) * rz / (4d0 * s(1:nx1)**2)) * &
                     (3d0 * zo(1:nx1,k) * dp%z(1:nx1,k) - &
                     zo2(1:nx1,k) * dp2%z(1:nx1,k)) - &
                     (rx / (8d0 * s(1:nx1) * delz)) * &
                     ((3d0 * (dp%x(1:nx1,k) * dz%z(1:nx1,k) - &
                     dp%z(1:nx1,k) * dz%x(1:nx1,k))) - &
                     (dp2%x(1:nx1,k) * dz_2%z(1:nx1,k) - &
                     dp2%z(1:nx1,k) * dz_2%x(1:nx1,k))) + &
                     0.25d0 * rz * Q * (3d0 * dj%z(1:nx1,k) - &
                     dj2%z(1:nx1,k))
end do

return
END SUBROUTINE get_nlin_Zx

END MODULE nonlinear