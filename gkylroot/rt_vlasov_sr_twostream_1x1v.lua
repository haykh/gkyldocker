local Vlasov = G0.Vlasov

-- Mathematical constants (dimensionless).
pi = math.pi

-- Physical constants (using normalized code units).
epsilon0 = 1.0 -- Permittivity of free space.
mu0 = 1.0 -- Permeability of free space.
mass_elc = 1.0 -- Electron mass.
charge_elc = -1.0 -- Electron charge.

n0 = 1.0 -- Reference number density.
-- T = 1e-4 -- Temperature (units of mc^2).
Vb = 1.0 / 20.0

alpha = 1.0e-3 -- Applied perturbation amplitude.
kx = 0.5 -- Perturbed wave number (x-direction).

-- Derived physical quantities (using normalized code units).
gamma = 1.0 / math.sqrt(1.0 - (Vb * Vb)) -- Gamma factor.
Ub = gamma * Vb -- Relativistic drift velocity (x-direction).
deltaUb = Ub / 25.0

-- Simulation parameters.
Nx = 512 -- Cell count (configuration space: x-direction).
Nvx = 2048 -- Cell count (velocity space: vx-direction).
Lx = 25.6 -- Domain size (configuration space: x-direction).
ux_max = 10.0 * Ub -- Domain boundary (velocity space: vx-direction).
poly_order = 2 -- Polynomial order.
basis_type = "serendipity" -- Basis function set.
time_stepper = "rk3" -- Time integrator.
cfl_frac = 0.5 -- CFL coefficient.

nx = 2.0
kx = nx * 2.0 * pi / Lx

t_end = 3000.0 -- Final simulation time.
num_frames = 30 -- Number of output frames.
field_energy_calcs = GKYL_MAX_INT -- Number of times to calculate field energy.
integrated_mom_calcs = GKYL_MAX_INT -- Number of times to calculate integrated moments.
integrated_L2_f_calcs = GKYL_MAX_INT -- Number of times to calculate L2 norm of distribution function.
dt_failure_tol = 1.0e-4 -- Minimum allowable fraction of initial time-step.
num_failures_max = 20 -- Maximum allowable number of consecutive small time-steps.

vlasovApp = Vlasov.App.new {

    tEnd = t_end,
    nFrame = num_frames,
    fieldEnergyCalcs = field_energy_calcs,
    integratedL2fCalcs = integrated_L2_f_calcs,
    integratedMomentCalcs = integrated_mom_calcs,
    dtFailureTol = dt_failure_tol,
    numFailuresMax = num_failures_max,
    lower = {0.0},
    upper = {Lx},
    cells = {Nx},
    cflFrac = cfl_frac,

    basis = basis_type,
    polyOrder = poly_order,
    timeStepper = time_stepper,

    -- Decomposition for configuration space.
    decompCuts = {8}, -- Cuts in each coodinate direction (x-direction only).

    -- Boundary conditions for configuration space.
    periodicDirs = {1}, -- Periodic directions (x-direction only).

    -- Electrons.
    elc = Vlasov.Species.new {
        modelID = G0.Model.SR,
        charge = charge_elc,
        mass = mass_elc,

        -- Velocity space grid.
        lower = {-ux_max},
        upper = {ux_max},
        cells = {Nvx},

        -- Initial conditions.
        numInit = 2,
        projections = { -- Two counter-streaming Maxwellians.
        {
            projectionID = G0.Projection.Func,

            init = function(t, xn)
                local ux = xn[2]
                local x = xn[1]
                local del = math.abs(ux - Ub) / deltaUb
                local n = 0.0
                if del < 0.5 then
                    n = (0.75 - del ^ 2)
                elseif del < 1.5 then
                    n = (0.5 * (1.5 - del) ^ 2)
                end
                return 0.5 * (1.0 + alpha * math.cos(kx * x)) * n0 * n / deltaUb
            end

            -- projectionID = G0.Projection.LTE,

            -- densityInit = function(t, xn)
            --     local x = xn[1]

            --     local n = 0.5 * (1.0 + alpha * math.cos(kx * x)) * n0 -- Total number density.
            --     return n
            -- end,
            -- temperatureInit = function(t, xn)
            --     return T -- Isotropic temperature.
            -- end,
            -- driftVelocityInit = function(t, xn)
            --     return Ub -- Total left-going relativistic drift velocity.
            -- end,

            -- correctAllMoments = true,
            -- useLastConverged = true
        }, {
            projectionID = G0.Projection.Func,

            init = function(t, xn)
                local ux = xn[2]
                local x = xn[1]
                local del = math.abs(ux + Ub) / deltaUb
                local n = 0.0
                if del < 0.5 then
                    n = (0.75 - del ^ 2)
                elseif del < 1.5 then
                    n = (0.5 * (1.5 - del) ^ 2)
                end
                return 0.5 * (1.0 + alpha * math.cos(kx * x)) * n0 * n / deltaUb
            end

            -- projectionID = G0.Projection.LTE,

            -- densityInit = function(t, xn)
            --     local x = xn[1]

            --     local n = 0.5 * (1.0 + alpha * math.cos(kx * x)) * n0 -- Total number density.
            --     return n
            -- end,
            -- temperatureInit = function(t, xn)
            --     return T -- Isotropic temperature.
            -- end,
            -- driftVelocityInit = function(t, xn)
            --     return -Ub -- Total right-going relativistic drift velocity.
            -- end,

            -- correctAllMoments = true,
            -- useLastConverged = true
        }},

        evolve = true, -- Evolve species?
        diagnostics = {G0.Moment.M0, G0.Moment.M1}
    },

    field = Vlasov.Field.new {
        epsilon0 = epsilon0,
        mu0 = mu0,

        -- Initial conditions function.
        init = function(t, xn)
            local x = xn[1]

            local Ex = -alpha * math.sin(kx * x) / kx -- Total electric field (x-direction).
            local Ey = 0.0 -- Total electric field (y-direction).
            local Ez = 0.0 -- Total electric field (z-direction).

            local Bx = 0.0 -- Total magnetic field (x-direction).
            local By = 0.0 -- Total magnetic field (y-direction).
            local Bz = 0.0 -- Total magnetic field (z-direction).

            return Ex, Ey, Ez, Bx, By, Bz, 0.0, 0.0
        end,

        evolve = true, -- Evolve field?
        elcErrorSpeedFactor = 0.0,
        mgnErrorSpeedFactor = 0.0
    }
}

vlasovApp:run()
