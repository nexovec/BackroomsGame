# MGL

Mathematics for Graphics in pure Lua (or Mathematics for OpenGL, also an anagram of https://glm.g-truc.net/0.9.9/index.html[GLM]; </br> an inspiration for the library with https://en.wikipedia.org/wiki/OpenGL_Shading_Language[GLSL]) is a math library for graphics purposes.

It depends on the dynamic https://github.com/ImagicTheCat/lua-xtype[xtype] system.

It aims to be simple, generic and optimized (mostly for LuaJIT).

See examples.

# Install

See link:src[], link:rockspecs[] or https://luarocks.org/modules/imagicthecat-0a6b669a3a/mgl[luarocks].

# API

## Module

```lua
-- Add MGL loader.
-- pattern: Lua pattern
-- callback(...): called when an undefined field is accessed with the specified pattern
--- ...: pattern captures (returned by string.match)
--- should return the field value
mgl.addLoader(pattern, callback)

-- Generate function.
-- name: identify the generated function for debug
mgl.genfunc(code, name)

-- Initialize operation multifunctions.
-- ...: list of identifiers
mgl.initmfs(...)
```

# Types

.MGL types may have predefined metamethods such as:
| Metamethod | Function |
|--------------|-----------|
| **tostring | tostring |
| **unm | unm |
| **add | xtype add |
| **sub | xtype sub |
| **mul | xtype mul |
| **div | xtype div |
| **mod | xtype mod |
| **pow | xtype pow |
| **eq | xtype eq |
| **lt | xtype lt |
| \_\_le | xtype le |

Types can have specialized metamethods; for example, to implement accessors.

NOTE: Accessors are implemented as simple as possible, they are check free.

# vec(D)

Generic vector type of dimension `D`, stored as an array/list of scalars (table).

```lua
-- Require vec(D) vector type.
-- D: (optional) dimension
-- return vec(D) or vec xtype
mgl.require_vec(D)

-- Loader pattern.
mgl.vecD

-- Accessors.
-- vec.x / vec.r (vec[1])
-- vec.y / vec.g (vec[2])
-- vec.z / vec.b (vec[3])
-- vec.w / vec.a (vec[4])

#vec -- dimension
```

# mat(N)x(M) / mat(N)

Generic matrix type of dimension `N x M`, stored as an array/list of row-major ordered scalars (table). Columns are vectors.

NOTE: The choice of the row-major order is about reading/writing a matrix content as we read/write text/code in English/Lua (left to right, top to bottom). +
The choice of columns as vectors is about following mathematical conventions (`M*v` to transform a vector).

```lua
-- Require mat(N)(M)/mat(N) vector type.
-- Matrix values are stored as a row-major ordered list; columns are vectors.
-- N: (optional) columns
-- M: (optional) rows (default: N)
-- return mat(N)(M)/mat(N) or mat xtype
mgl.require_mat(N, M)

-- Loader patterns.
mgl.matNxM
mgl.matN -- square

-- Vector accessor (get/set column vector).
-- idx: column index
-- vec: (optional) vec(M), set column
mat:v(idx, vec)
```

# Operators

Binary operators are implemented through _xtype_ op multifunctions.

## **`tostring`**

`(vec(D): a): string`</br>
`(mat(N)x(M): a): string`</br>

## **`equal`**

`(vec(D): a, vec(D): b): boolean`</br>
`(mat(N)x(M): a, mat(N)x(M): b): boolean`</br>

## **`unm`**

Unary minus.

`(vec(D): a): vec(D)`</br>
`(mat(N)x(M): a): mat(N)x(M)`</br>

## **`add`**

`(vec(D): a, vec(D): b): vec(D)`</br>
`(mat(N)x(M): a, mat(N)x(M): b): mat(N)x(M)`</br>

## **`sub`**

`(vec(D): a, vec(D): b): vec(D)`</br>
`(mat(N)x(M): a, mat(N)x(M): b): mat(N)x(M)`</br>

## **`mul`**

`(vec(D): a, vec(D): b): vec(D)` Component-wise multiplication.</br>
`(vec(D): a, number: b): vec(D)`</br>
`(number: a, vec(D): b): vec(D)`</br>
`(mat(N)x(M): a, mat(O)x(N) or vec(N): b): mat(O)x(M) or vec(M)` Matrix/vector general multiplication. Will return a vector if the result has a single column.</br>
`(mat(N)x(M): a, number: b): mat(N)x(M)`</br>
`(number: a, mat(N)x(M): b): mat(N)x(M)`</br>

## **`div`**

`(vec(D): a, vec(D): b): vec(D)` Component-wise division.</br>
`(vec(D): a, number: b): vec(D)`</br>
`(mat(N)x(M): a, number: b): mat(N)x(M)`</br>

# Operations

Operations are _xtype_ mulztifunctions.

### **`vec(D)`**

Vector constructor.

`(number: scalar): vec(D)` Scalar constructor.
`(table: list): vec(D)` List constructor. `#list >= D`
`(number or vec(D): ...): vec(D)` Composed constructor. Any combination of scalars and vectors matching the result vector size.
`(vec(D+x): v): vec(D)` Truncate constructor.

### **`mat(N)x(M) / mat(N)`**

Matrix constructor.

`(number: scalar): mat(N)x(M)` Scalar constructor. Create matrix with `scalar` along the identity diagonal.</br>
`(table: list): mat(N)x(M)` List constructor. `#list >= N*M`</br>
`(vec(M): columns...): mat(N)x(M)` Column vectors constructor. `#columns... == N`</br>
`(mat(Na, Ma): a): mat(N)x(M)` Generic matrix constructor. Copy/extend/truncate a same/smaller/bigger matrix (fill with identity when extending).</br>

### **`copy`**

`(vec(D): dst, vec(D): src)`</br>
`(mat(N)x(M): dst, mat(N)x(M): src)`</br>

### **`length`**

`(vec(D): a): number` Vector length (Euclidean).</br>

### **`normalize`**

`(vec(D): a): vec(D)` Vector normalization.</br>

### **`dot`**

`(vec(D): a, vec(D): b): number` Dot product.</br>

### **`cross`**

`(vec3: a, vec3: b): vec3` Cross product.</br>

### **`transpose`**

`(mat(N)x(M): a): mat(M)x(N)`</br>

### **`determinant`**

`(mat2: a): number`</br>
`(mat3: a): number`</br>
`(mat4: a): number`</br>

### **`inverse`**

`(mat2: a): mat2, number` Compute inverse matrix. Also returns determinant.</br>
`(mat3: a): mat3, number` Compute inverse matrix. Also returns determinant.</br>
`(mat4: a): mat4, number` Compute inverse matrix. Also returns determinant.</br>

### **`translate`**

`(vec2: a): mat3` Translate identity (2D homogeneous).</br>
`(vec3: a): mat4` Translate identity (3D homogeneous).</br>

---

### **`rotate(number: theta): mat3`**

### **`rotate(vec3: axis, number: theta): mat4`**

Rotate in radians

---

### **`scale(vec2: a): mat3`**

### **`scale(vec3: a): mat4`**

---

### **`orthographic(number: left, number: right, number: bottom, number: top, number: near, number: far): mat4`**

GL compatible orthographic projection.</br>

---

### **`perspective(number: hfov, number: aspect, number: near, number: far): mat4`**

GL compatible perspective projection. `hfov` is in radians.</br>

---

# Performances

> TIP: An operator/operation definition can be retrieved and cached with `multifunction:resolve(...)` when optimizations are needed.</br>

## Comparisons

See https://github.com/ImagicTheCat/MGL/blob/master/README.adoc
