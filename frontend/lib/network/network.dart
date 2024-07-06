import 'dart:convert';

import 'package:dio/dio.dart';

import 'res.dart';
import 'models.dart';

export 'models.dart';
export 'res.dart';

class Network {
  static Network? instance;
  static String serverAddr="http://localhost:1323";
  Network._internal();
  final dio=Dio();

  factory Network() => instance ??= Network._internal();

  Future<Res<Account>> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final queryData={
      "client_id":"000000",
      "client_secret":"999999",
      "grant_type":"password",
      "scope":"read"
    };
    final formData = FormData.fromMap(
      {
        "username": username,
        "password": password,
      },
    );
    final response=await dio.post("$serverAddr/user/login",queryParameters: queryData,data:formData);
    print(response);
    final user=await dio.get<Map<String,dynamic>>("$serverAddr/api/user/get",queryParameters: {"username":username});

    return const Res(Account(
      avatar: "$serverAddr/api/file/download?url=$user.ContentUrl",
      nickname: "Testuser",
      username: "testuser",
      token: "testuser_token",
    ));
  }

  Future<Res<Account>> register(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Res(Account(
      avatar: "https://avatars.githubusercontent.com/u/67669799?v=4&size=64",
      nickname: "Testuser",
      username: "testuser",
      token: "testuser_token",
    ));
  }

  Future<Res<List<Memo>>> getHomePage(int page) async {
    await Future.delayed(const Duration(seconds: 1));
    return Res([
      Memo(
        id: 1,
        content: _testMemoContent,
        date: DateTime.parse("2024-07-03"),
        author: null,
        linksCount: 1,
        repliesCount: 1,
        isLiked: false,
      )
    ], subData: 1);
  }

  Future<Res<bool>> favoriteOrUnfavorite(int memoId) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Res(true);
  }
}

const _testMemoContent = r'''
## 插入排序

### 简介
先考虑单独第一个元素, 它显然是有序的, 然后依次添加下一个元素
在添加元素时, 将其插入至正确的位置
可知, 每次操作完成时, 得到的数组是有序的

### 实现
```c++
int nums[6];  
for(int & num : nums){  
    std::cin >> num;  
}  
print("Input is: ");  
print(nums, 6);  
  
for(int i=1; i<6; i++){
    int value = nums[i];  
    int j = i-1;  
  
    while(j >= 0 && nums[j] > value){  
        nums[j+1] = nums[j];  
        j--;  
    }  
  
    nums[j+1] = value;  
}
  
print("Output is: ");  
print(nums, 6);
```

### 复杂度
时间复杂度: $O(n) = n^2$
空间复杂度: $O(n) = n$

## 归并排序

### 简介
使用**分治法**, 将列表分为两部分, 分别使之有序, 再进行合并

### 实现
```c++
void sort(int* nums, int l, int r){  
    if(r-1 == l){  
        return;  
    }  
    int mid = (r + l) / 2;  
    sort(nums, l, mid);  
    sort(nums, mid, r);  
    int p = 0, q = 0, t = 0;  
    int lNums[mid - l];  
    int rNums[r - mid];  
  
    for(q = 0; q<mid - l; q++){  
        lNums[q] = nums[l + q];  
    }  
  
    for(t = 0; t<r-mid; t++){  
        rNums[t] = nums[mid + t];  
    }  
  
    q = 0, t = 0;  
  
    for(p=l;p<r;p++){  
        if(q == mid-l){  
            nums[p] = rNums[t];  
            t++;  
        }else if(t == r - mid){  
            nums[p] = lNums[q];  
            q++;  
        }else {  
            if (lNums[q] < rNums[t]) {  
                nums[p] = lNums[q];  
                q++;  
            } else {  
                nums[p] = rNums[t];  
                t++;  
            }  
        }  
    }  
}
```
将数组分成左右两部分, 使用递归的方式分别对两边排序, 再进行合并
合并时, 分别将两边数组复制一份, 创建三个变量对排序数组, 左数组, 右数组进行索引, 比较左右数组首项后修改排序数组
''';
