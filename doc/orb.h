#ifndef __ORB_H__
#define __ORB_H__

namespace orb
{

class CoordGgp
{
    double lat; ///< latitude  [-pi/2, pi/2] (S - N)
    double lng; ///< longitude [-pi, pi [ (E - W)
    double alt; ///< altitude  [0, +inf[
};

// right-handed x (thumb) y (index) z (middle)
class CoordGct
{
    double x;   ///< on equatorial plane, pointing to the reference meridian (lat=0, lng=0, alt=1)
    double y;   ///< pointing towards north pole (lat=pi/2, lng=0, alt=1)
    double z;   ///< on equatorial plane, pointing to the extrem west meridian (lat=0, lng=pi/2, alt=1)
};

static inline void coord_ggp2gct(CoordGct *gct, const CoordGgp *ggp)
{
    gct->x = cos(ggp->lat) * cos(ggp->lng) * ggp->alt;
    gct->y = sin(ggp->lat) * ggp->alt;
    gct->z = cos(ggp->lat) * sin(ggp->lng) * ggp->alt;
};

static inline void coord_gct2ggp(CoordGgp *ggp, const CoordGct *gct)
{
    ggp->alt = sqrt(gct->x * gct->x + gct->y * gct->y + gct->z + gct->z);

    if (gct->z == 0)
        ggp->lng = 0;
    else if (gct->z < 0)
        ggp->lng = -acos(gct->x / sqrt(gct->x * gct->x + gct->z + gct->z));
    else if (gct->z > 0)
        ggp->lng = acos(gct->x / sqrt(gct->x * gct->x + gct->z + gct->z));

    ggp->lat = asin(gct->y / ggp->alt);
}

class Camera : public CoordGct
{
	double yaw;	// rotate around y axis (look left/right)
	double pitch;	// rotate around x axis (look up/down)
	double roll;	// rotate around z axis (tilt on the left/right)
	double fov;	// Field Of View angle.
};

class Projection
{
	double proximityDistance;	// distance behind which objects are not drawn
	double horizonDistance;		// distance beyond which objects are not drawn
	double ratioXY;			// ratio between x and y 2D coordinates
};

} // namespace orb

#endif __ORB_H__
