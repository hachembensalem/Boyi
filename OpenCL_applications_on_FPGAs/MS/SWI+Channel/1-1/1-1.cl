// Define the color black as 0
#define BLACK 0x00000000

#pragma OPENCL EXTENSION cl_khr_fp64 : enable

// Mandelbrot set: zn+1 = zn^2 + c;

typedef struct {
	int x;
	int y;
	int iter;
} Channel_type;

	channel Channel_type chan;


__kernel 

void hw_mandelbrot_frame ( const double x0, const double y0, 
						const double stepSize, const unsigned int maxIterations){

	for (int windowPosX = 0; windowPosX < 800; windowPosX ++){
		for(int windowPosY = 0; windowPosY < 640; windowPosY ++){
		
			const double stepPosX = x0 + (windowPosX * stepSize);
			const double stepPosY = y0 - (windowPosY * stepSize);

			double x = 0.0;
			double y = 0.0;
			double xSqr = 0.0;
			double ySqr = 0.0;
			unsigned int iterations = 0;

  			//#pragma unroll 20
			while (	xSqr + ySqr < 4.0 && iterations < maxIterations){
				xSqr = x*x;
				ySqr = y*y;

				y = 2*x*y + stepPosY;
				x = xSqr - ySqr + stepPosX;

				iterations++;
			}

			Channel_type c;
			c.x	   = windowPosX;
			c.y    = windowPosY;
			c.iter = iterations; 
			write_channel_altera(chan, c);
		}	
	}	
}


__kernel void out ( const unsigned int maxIterations, __global unsigned int *restrict framebuffer,
					__constant const unsigned int *restrict colorLUT, const unsigned int windowWidth)
{
	for (int i = 0; i < 512000; i ++){
		Channel_type c = read_channel_altera(chan);
		int x    = c.x;
		int y    = c.y;
		int iter = c.iter;

		framebuffer[windowWidth * y + x] = (iter == maxIterations)? BLACK : colorLUT[iter];
	}
}
