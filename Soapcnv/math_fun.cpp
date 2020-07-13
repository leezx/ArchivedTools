#include <cmath>
#include <algorithm>
#include "math_fun.h"
#include <iostream>
#include <boost/math/distributions/poisson.hpp>

using namespace std;

//binomial test 
float binomial_test(float p0, int x, int n)
{
	float  p_val = 0;
	float p = x / (float)n;

	float q0 = 1 - p0;
	if(p < p0)
	{
		for(int i = 0; i <= x; i++)
			p_val += (float)C_calc(i,n) * pow(p0, (float)i) * pow(q0, (float)(n -i));
	}
	else
	{
		for(int i = x; i <= n; i++)
			p_val += (float)C_calc(i,n) * pow(p0, (float)i) * pow(q0, (float)(n -i));

	}

	p_val = min(2 * p_val, 1.0f);

	return p_val;
}


double C_calc(double x , double n)
{
	double devisor = 1;
	double devidend = 1;

	if(x > n/2)x = n - x;

	for (double i = 0; i < x; i++)devidend *= (n -i);

	for (double i = 2; i <=x; i++)devisor *= i;

	return devidend / devisor;
}

double fact(double n)
{
	double ret = 1;
	for(double i = 1; i <= n; i++) ret *= i;

	return ret;
}

double p_poisson(float lamda, int x)
{
	return exp(double(-lamda)) * pow((double)lamda, (double)x) / fact(x);
}





