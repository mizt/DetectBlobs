#import <Foundation/Foundation.h>
#import <vector>

std::vector<std::vector<unsigned int>> classification;
std::vector<std::vector<std::vector<int>>> indices;

int main(int argc, char *argv[]) {
	@autoreleasepool {
		
		double then = CFAbsoluteTimeGetCurrent();

		NSString *src = [NSString stringWithContentsOfFile:@"./test.obj" encoding:NSUTF8StringEncoding error:nil];
		NSArray *lines = [src componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
		
		NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
				
		std::vector<float> v;
		std::vector<unsigned int> f;
		
		float minmax[3][2] = {
			{32767,-32768},
			{32767,-32768},
			{32767,-32768}
		};
		
		for(int k=0; k<[lines count]; k++) {
			NSArray *arr = [lines[k] componentsSeparatedByCharactersInSet:whitespaces];
			if([arr count]>0) {
				if([arr[0] isEqualToString:@"v"]) {
					
					float x = [arr[1] doubleValue];
					float y = [arr[2] doubleValue];
					float z = [arr[3] doubleValue];
					
					if(x<minmax[0][0]) minmax[0][0] = x;
					if(minmax[0][1]<x) minmax[0][1] = x;
					
					if(y<minmax[1][0]) minmax[1][0] = y;
					if(minmax[1][1]<y) minmax[1][1] = y;
					
					if(z<minmax[2][0]) minmax[2][0] = z;
					if(minmax[2][1]<z) minmax[2][1] = z;
					
					v.push_back(x);
					v.push_back(y);
					v.push_back(z);
					
					v.push_back([arr[4] doubleValue]);
					v.push_back([arr[5] doubleValue]);
					v.push_back([arr[6] doubleValue]);
				}
				else if([arr[0] isEqualToString:@"f"]) {
					f.push_back([arr[1] intValue]-1);
					f.push_back([arr[2] intValue]-1);
					f.push_back([arr[3] intValue]-1);
				}
			}
		}
		
		NSLog(@"v = %ld",v.size()/6);
		
		unsigned int verticesNum = v.size()/6;
		
		long *count = new long[verticesNum];
		long *use = new long[verticesNum];
		for(int n=0; n<verticesNum; n++) {
			count[n] = -1;
			use[n] = -1;
		}
		
		float mid[3] = {
			minmax[0][0]+(minmax[0][1]-minmax[0][0])*0.5f,
			minmax[1][0]+(minmax[1][1]-minmax[1][0])*0.5f,
			minmax[2][0]+(minmax[2][1]-minmax[2][0])*0.5f,
		};
		
		NSLog(@"%f",CFAbsoluteTimeGetCurrent()-then);
		then = CFAbsoluteTimeGetCurrent();
		
		const int NUM = 2*2*2;
		
		for(int c=0; c<NUM; c++) {
			classification.push_back({});
			indices.push_back({});
		}
		
		for(int n=0; n<verticesNum; n++) {
			
			float x = v[n*6+0];
			float y = v[n*6+1];
			float z = v[n*6+2];
			
			unsigned int c = 0;
			c|=(x<mid[0])?0:1<<2; 
			c|=(y<mid[1])?0:1<<1; 
			c|=(z<mid[2])?0:1; 
			
			classification[c].push_back(n);
		}
		
		dispatch_group_t group = dispatch_group_create();
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
		
		for(int c=0; c<NUM; c++) {
			
			dispatch_group_async(group,queue,^{
			
				std::vector<unsigned int> *src = &(classification[c]);
				std::vector<std::vector<int>> *dst = &(indices[c]);
			
				for(int n=0; n<src->size(); n++) {
					unsigned int p = (*src)[n];
					if(use[p]==-1) {
						use[p] = p;
						float x = v[p*6+0];
						float y = v[p*6+1];
						float z = v[p*6+2];
						dst->push_back({});
						std::vector<int> *tmp = &(*dst)[dst->size()-1];
						tmp->push_back(p);
						for(int k=n+1; k<src->size(); k++) {
							unsigned int q = (*src)[k];
							if(x==v[q*6+0]&&y==v[q*6+1]&&z==v[q*6+2]) {
								use[q] = p;
								tmp->push_back(q);
							}
						}
					}
				}
			});
		}
		
		dispatch_group_wait(group,DISPATCH_TIME_FOREVER);

		std::vector<std::vector<int>> pack;
		
		for(int c=0; c<NUM; c++) {
			
			std::vector<std::vector<int>> *src = &(indices[c]);
			NSLog(@"indices[%d].size is %ld",c,src->size());
			
			for(int n=0; n<src->size(); n++) {
				
				pack.push_back({});
				std::vector<int> *dst = &(pack[pack.size()-1]);
				std::vector<int> *list = &((*src)[n]);
				for(int k=0; k<list->size(); k++) {
					dst->push_back((*list)[k]);
				}
			}
		}
				
		float *vercites = new float[pack.size()*6];
		
		for(int n=0; n<pack.size(); n++) {
			
			float r = 0;
			float g = 0;
			float b = 0;
			
			std::vector<int> *src = &(pack[n]);
			
			for(int k=0; k<src->size(); k++) {
				
				count[(*src)[k]] = n;
				
				unsigned int addr = (*src)[k]*6+3;
				r+=v[addr+0];
				g+=v[addr+1];
				b+=v[addr+2];
			}
			
			r/=pack[n].size();
			g/=pack[n].size();
			b/=pack[n].size();
			
			vercites[n*6+0] = v[(*src)[0]*6+0];
			vercites[n*6+1] = v[(*src)[0]*6+1];
			vercites[n*6+2] = v[(*src)[0]*6+2];
			vercites[n*6+3] = r;
			vercites[n*6+4] = g;
			vercites[n*6+5] = b;
		}
		
		NSLog(@"pack.size is %lu",pack.size());

		NSMutableString *obj = [NSMutableString stringWithString:@""];
		
		for(int n=0; n<pack.size(); n++) {
			[obj appendString:[NSString stringWithFormat:@"v %0.4f %0.4f %04f %0.4f %0.4f %0.4f\n",
				vercites[n*6+0],
				vercites[n*6+1],
				vercites[n*6+2],
				vercites[n*6+3],
				vercites[n*6+4],
				vercites[n*6+5]
			]];
		} 
		
		unsigned int facesNum = f.size()/3;
		for(int n=0; n<facesNum; n++) {
			[obj appendString:[NSString stringWithFormat:@"f %d %d %d\n",
				1+(int)(count[f[n*3+0]]),
				1+(int)(count[f[n*3+1]]),
				1+(int)(count[f[n*3+2]])
			]];
		} 
		
		[obj writeToFile:@"marge.obj" atomically:YES encoding:NSUTF8StringEncoding error:nil];
				
		NSLog(@"%f",CFAbsoluteTimeGetCurrent()-then);
		then = CFAbsoluteTimeGetCurrent();

	}
}