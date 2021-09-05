#include<stdio.h>
#include<stdlib.h>
#include<string.h>
int main()
{
	int i=0;
	int j=12;

	
		j = 32*12;
		switch(j)
		{
		case 1: i=9;
			switch(i)
			{
			case 1: i=11;break;
			case 2:i=82; break;
			default:j=9;		
				}
			break;
		case 2:i=8; break;
		default:j=0;		
		}
	
}
