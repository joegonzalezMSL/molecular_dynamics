# Definition of SNAP+ZBL potential.
variable zblcutinner equal 0.1 #0.38
variable zblcutouter equal 0.2
variable zblz equal  10 #500

# Specify hybrid with SNAP, ZBL, and long-range Coulomb

pair_style hybrid/overlay &
zbl ${zblcutinner} ${zblcutouter} &
snap
pair_coeff 1 1 zbl ${zblz} ${zblz}
pair_coeff * * snap C.snapcoeff C.snapparam C

