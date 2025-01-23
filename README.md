# Raymarching on Surfaces

A visual exploration of ray marching techniques on various geometric surfaces, including translation surfaces, mirror rooms, and cube surfaces.

## Description

This project implements ray marching algorithms using WebGL shaders to visualize different mathematical surfaces and geometric spaces. The visualizations include:

- Translation surfaces
- Mirror rooms
- Cube surface 

The project uses shader-based ray marching to create accurate and performant visualizations of these mathematical concepts.

## Getting Started

### Prerequisites

- A modern web browser with WebGL support
- A local web server (any simple HTTP server will work)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/raymarching-on-surfaces.git
```

2. Navigate to the project directory:
```bash
cd raymarching-on-surfaces
```

3. Start a local server. For example, using Python:
```bash
# Python 3
python -m http.server

# Python 2
python -m SimpleHTTPServer
```

4. Open your web browser and navigate to:
```
http://localhost:8000
```

## Implementation Details

The project is built with WebGL through the THREE.js framework. Key features include:

- Custom JavaScript for keyboard and mouse input control
- ray marching algorithms implemented in GLSL fragment shaders
- Real-time rendering of flat surfaces with dynamic camera perspectives

## Live Demo

Access the interactive visualization at [HEGL Lab Web Interface](https://hegl.mathi.uni-heidelberg.de/galleries/online-apps/)

## Original Repository

This project is based on work from [HEGL Lab](https://github.com/hegl-lab/Independent-SS22-Raymarching-Flat-Surfaces)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
