import postgkyl as pg
import numpy as np


def ReadFields(path: str, sim: str, step: int):
    gkyl_data = pg.data.GData(f"{path}/{sim}-field_{step}.gkyl")
    gkyl_interp = pg.data.GInterpModal(gkyl_data, 2, "ms")
    field_data = {}
    for fi, f in enumerate(["e", "b"]):
        for ci, c in enumerate(["x", "y", "z"]):
            field = f"{f}{c}"
            fn = ci + 3 * fi
            field_interp = gkyl_interp.interpolate(fn)
            assert field_interp is not None, f"{field} data is None"
            field_val = np.array(field_interp[1][:]).flatten()
            field_data[field] = field_val
            if fi == 0 and ci == 0:
                x_grid = np.array(field_interp[0][:])
                x_grid = (x_grid[1:] + x_grid[:-1]) * 0.5
                field_data["x"] = x_grid
    return field_data


def ReadDist(path: str, sim: str, dist: str, step: int):
    gkyl_data = pg.data.GData(f"{path}/{sim}-{dist}_{step}.gkyl")
    gkyl_interp = pg.data.GInterpModal(gkyl_data, 2, "ms")
    dist_interp = gkyl_interp.interpolate()
    assert dist_interp is not None, f"{dist} data is None"
    x_ux_grid, dist_val = dist_interp
    x_grid = np.array(x_ux_grid[0][:])
    ux_grid = np.array(x_ux_grid[1][:])
    dist_val = np.array(dist_val[:]).T.squeeze()
    return {"x": x_grid, "ux": ux_grid, dist: dist_val}
