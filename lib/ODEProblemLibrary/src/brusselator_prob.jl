function brusselator_f(x, y, t)
    ifelse((((x - 0.3)^2 + (y - 0.6)^2) <= 0.1^2) &&
               (t >= 1.1), 5.0, 0.0)
end
function limit(a, N)
    if a == N + 1
        return 1
    elseif a == 0
        return N
    else
        return a
    end
end
function brusselator_2d_loop(du, u, p, t)
    @inbounds begin
        A, B, α, xyd, dx, N = p
        α = α / dx^2
        for I in CartesianIndices((N, N))
            x = xyd[I[1]]
            y = xyd[I[2]]
            i = I[1]
            j = I[2]
            ip1 = limit(i + 1, N)
            im1 = limit(i - 1, N)
            jp1 = limit(j + 1, N)
            jm1 = limit(j - 1, N)
            du[i, j, 1] = α * (u[im1, j, 1] + u[ip1, j, 1] + u[i, jp1, 1] + u[i, jm1, 1] -
                           4u[i, j, 1]) +
                          B + u[i, j, 1]^2 * u[i, j, 2] - (A + 1) * u[i, j, 1] +
                          brusselator_f(x, y, t)
        end
        for I in CartesianIndices((N, N))
            i = I[1]
            j = I[2]
            ip1 = limit(i + 1, N)
            im1 = limit(i - 1, N)
            jp1 = limit(j + 1, N)
            jm1 = limit(j - 1, N)
            du[i, j, 2] = α * (u[im1, j, 2] + u[ip1, j, 2] + u[i, jp1, 2] + u[i, jm1, 2] -
                           4u[i, j, 2]) +
                          A * u[i, j, 1] - u[i, j, 1]^2 * u[i, j, 2]
        end
    end
end
function init_brusselator_2d(xyd)
    N = length(xyd)
    u = zeros(N, N, 2)
    for I in CartesianIndices((N, N))
        x = xyd[I[1]]
        y = xyd[I[2]]
        u[I, 1] = 22 * (y * (1 - y))^(3 / 2)
        u[I, 2] = 27 * (x * (1 - x))^(3 / 2)
    end
    u
end
xyd_brusselator = range(0, stop = 1, length = 32)

"""
2D Brusselator

```math
\\frac{\\partial u}{\\partial t} = 1 + u^2v - 4.4u + \\alpha(\\frac{\\partial^2 u}{\\partial x^2} + \\frac{\\partial^2 u}{\\partial y^2}) + f(x, y, t)
```
```math
\\frac{\\partial v}{\\partial t} = 3.4u - u^2v + \\alpha(\\frac{\\partial^2 u}{\\partial x^2} + \\frac{\\partial^2 u}{\\partial y^2})
```

where

``f(x, y, t) = \\begin{cases} 5 & \\quad \\text{if } (x-0.3)^2+(y-0.6)^2 ≤ 0.1^2 \\text{ and } t ≥ 1.1 \\\\ 0 & \\quad \\text{else} \\end{cases}``

and the initial conditions are

```math
u(x, y, 0) = 22\\cdot y(1-y)^{3/2}
```
```math
v(x, y, 0) = 27\\cdot x(1-x)^{3/2}
```

with the periodic boundary condition

```math
u(x+1,y,t) = u(x,y,t)
```
```math
u(x,y+1,t) = u(x,y,t)
```

From Hairer Norsett Wanner Solving Ordinary Differential Equations II - Stiff and Differential-Algebraic Problems Page 152
"""
prob_ode_brusselator_2d = ODEProblem(brusselator_2d_loop,
                                     init_brusselator_2d(xyd_brusselator),
                                     (0.0, 11.5),
                                     (3.4, 1.0, 10.0,
                                      xyd_brusselator, step(xyd_brusselator),
                                      length(xyd_brusselator)))

const N_brusselator_1d = 40

function brusselator_1d_loop(du, u, p, t)
    A, B, alpha, dx = p
    alpha = alpha / dx^2
    @inbounds for i in 2:(N - 1)
        x = xyd_brusselator[i]
        ip1, im1 = i + 1, i - 1
        du[i, 1] = alpha * (u[im1, 1] + u[ip1, 1] - 2u[i, 1]) +
                   A + u[i, 1]^2 * u[i, 2] - (B + 1) * u[i, 1]
        du[i, 2] = alpha * (u[im1, 2] + u[ip1, 2] - 2u[i, 2]) +
                   B * u[i, 1] - u[i, 1]^2 * u[i, 2]
    end
end

function init_brusselator_1d(N)
    u = zeros(N, 2)
    x = range(0, stop = 1, length = N)
    for i in 1:N
        u[i, 1] = 1 + sin(2pi * x[i])
        u[i, 2] = 3.0
    end
    u
end

"""
1D Brusselator

```math
\\frac{\\partial u}{\\partial t} = A + u^2v - (B+1)u + \\alpha\\frac{\\partial^2 u}{\\partial x^2}
```
```math
\\frac{\\partial v}{\\partial t} = Bu - u^2v + \\alpha\\frac{\\partial^2 u}{\\partial x^2}
```

and the initial conditions are

```math
u(x,0) = 1+\\sin(2π x)
```
```math
v(x,0) = 3
```

with the boundary condition

```math
u(0,t) = u(1,t) = 1
```
```math
v(0,t) = v(1,t) = 3
```

From Hairer Norsett Wanner Solving Ordinary Differential Equations II - Stiff and Differential-Algebraic Problems Page 6
"""
prob_ode_brusselator_1d = ODEProblem(brusselator_1d_loop,
                                     init_brusselator_1d(N_brusselator_1d),
                                     (0.0, 10.0),
                                     (1.0, 3.0, 1 / 41, zeros(N_brusselator_1d)))
