#ifndef _MATH_FUN_H_
#define _MATH_FUN_H_

float binomial_test(float p0, int x, int n);

double fact(double n);

double C_calc(double x , double n);

double p_poisson(float lamda, int x);

//template <typename Iter, typename ValueType> double sd_calc(Iter start, Iter end, ValueType & mean_val);
template <typename Iter, typename ValueType> double sd_calc(Iter start, Iter end, ValueType & mean_val)
{
	double sum = 0;
	size_t cnt = 0;
	for (Iter it = start; it != end; it++) {
		sum += (*it - mean_val) * (*it - mean_val);
		cnt++;
	}
	
	return sqrt(sum / (cnt - 1));
}

#endif //_MATH_FUN_H_
