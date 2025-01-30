#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import <vector>
#import <numeric>

void search(std::vector<std::vector<unsigned int>> *connections, unsigned int target, long *use, int depth) {
	
	std::vector<unsigned int> *list = &((*connections)[target]);
	for(int k=0; k<list->size(); k++) {
		unsigned int tmp = (*list)[k];
		if(use[tmp]==-1) {
			use[tmp] = depth;
			search(connections,tmp,use,depth);
		}
	}
}

int main(int argc, char *argv[]) {
	@autoreleasepool {
		
		double then = CFAbsoluteTimeGetCurrent();
		srandom(then);

		NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
		
		NSString *src = [NSString stringWithContentsOfFile:@"./test.obj" encoding:NSUTF8StringEncoding error:nil];
		NSArray *lines = [src componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
						
		std::vector<simd::float3> _v;
		std::vector<simd::uint3> _f;
		
		for(int k=0; k<[lines count]; k++) {
			NSArray *arr = [lines[k] componentsSeparatedByCharactersInSet:whitespaces];
			if([arr count]>0) {
				if([arr[0] isEqualToString:@"v"]) {
					
					_v.push_back(simd::float3{
						[arr[1] floatValue],
						[arr[2] floatValue],
						[arr[3] floatValue],
					});
					
				}
				else if([arr[0] isEqualToString:@"f"]) {
					
					_f.push_back(simd::uint3{
						(unsigned int)([arr[1] intValue]-1),
						(unsigned int)([arr[2] intValue]-1),
						(unsigned int)([arr[3] intValue]-1)
					});
				}
			}
		}
				
		unsigned int verticesNum = _v.size();
		unsigned int facesNum = _f.size();

		std::vector<std::vector<unsigned int>> connections;
		for(int n=0; n<verticesNum; n++) {
			connections.push_back({});
		}
		
		for(int n=0; n<facesNum; n++) {
			
			connections[_f[n].x].push_back(_f[n].y);
			connections[_f[n].x].push_back(_f[n].z);
			
			connections[_f[n].y].push_back(_f[n].x);
			connections[_f[n].y].push_back(_f[n].z);
			
			connections[_f[n].z].push_back(_f[n].x);
			connections[_f[n].z].push_back(_f[n].y);
		} 
		
		long *use = new long[verticesNum];
		for(int n=0; n<verticesNum; n++) {
			use[n] = -1;
		}
		
		long depth = -1;
		
		for(int n=0; n<verticesNum; n++) {
			if(use[n]==-1) {
				use[n] = ++depth;
				search(&connections,n,use,depth);
			}
		}
		
		if(depth!=-1) {
			
			++depth;
			
			NSLog(@"depth is %ld",depth);

			unsigned int *point = new unsigned int[depth];
			for(int n=0; n<depth; n++) point[n] = 0;
			
			for(int n=0; n<verticesNum; n++) {
				if(use[n]!=-1) {
					point[use[n]]++;
				}
			}
			
			std::vector<int> index(depth);
			std::iota(index.begin(),index.end(),0);
			
			std::sort(
				index.begin(),index.end(),
				[&](int x, int y) { return point[x]>point[y]; }
			);
						
			simd::float3 *colors = new simd::float3[depth];
			for(int n=0; n<depth; n++) {
				
				if(n==0) {
					colors[n].x = colors[n].y = colors[n].z = 0.75;
				}
				else {
					colors[n].x = (random()%255)/255.0;
					colors[n].y = (random()%255)/255.0;
					colors[n].z = (random()%255)/255.0;
				}
			}
			
			for(int n=0; n<depth; n++) {

				std::vector<simd::float3> v;
				std::vector<simd::uint3> f;
				
				unsigned int o = 0;

				int tmp = index[n];
				
				simd::float3 color = colors[n];
				
				for(int k=0; k<facesNum; k++) {
					
					if(use[_f[k].x]==tmp&&use[_f[k].y]==tmp&&use[_f[k].z]==tmp) {
						
						v.push_back(_v[_f[k].x]);
						v.push_back(_v[_f[k].y]);
						v.push_back(_v[_f[k].z]);
						
						f.push_back(simd::uint3{o,o+1,o+2});
						
						o+=3;
					}
				}
				
				NSMutableString *obj = [NSMutableString stringWithString:@""];
				
				for(int k=0; k<v.size(); k++) {
					
					[obj appendString:[NSString stringWithFormat:@"v %f %f %f %f %f %f\n",v[k].x,v[k].y,v[k].z,color.x,color.y,color.z]];
					
				}
				
				for(int k=0; k<f.size(); k++) {
							
					[obj appendString:[NSString stringWithFormat:@"f %d %d %d\n",1+f[k].x,1+f[k].y,1+f[k].z]];
								
				}
				
				[obj writeToFile:[NSString stringWithFormat:@"./dst/%d.obj",n] atomically:YES encoding:NSUTF8StringEncoding error:nil];
				
				
				f.clear();
				v.clear();

			}
			
			_f.clear();
			_v.clear();
			
			index.clear();
			
			delete[] point;
			delete[] colors;
		}
		
		NSLog(@"%f",CFAbsoluteTimeGetCurrent()-then);
	}
}