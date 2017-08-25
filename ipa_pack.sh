#! /bin/sh

param=$1
echo "开始执行shell脚本"

#项目代码根目录                                  
g_main_proj_directory="/Users/shenjie/Documents/Myproject/9inHelper/9inHelper" 

#要打包的target名称 支持逗号拼接
g_target_name="ArtOfWuShu,ArtOfWuShu"   

#资源要拷贝到的目录
g_dest_res_path="${g_main_proj_directory}Resource/" 

#打包所用资源的路径 支持逗号拼接
g_res_path="/Users/shenjie/Documents/Myproject/9inHelper/9inHelper/9inHelper/Resource/sound,/Users/shenjie/Documents/Myproject/9inHelper/9inHelper/9inHelper/Resource/sound"

#打包所用资源的名称 nei／wai
g_res_name="wai" 

#打包模式 Debug/Release
development_mode=Release 

#build文件夹路径                                                          
g_build_path=${g_main_proj_directory}/build

#exportOptions.plist文件所在路径
exportOptionsPlistPath=${g_main_proj_directory}/9inHelper/exportOptions.plist

#导出.ipa文件所在路径
exportFilePath=${g_main_proj_directory}/products/ipa/${development_mode}/$(date +%y%m%d_%H%M)

#清理工程
clear_mainproj()
{
    cd $g_main_proj_directory
    rm -r $apppath
    mkdir $apppath
      
    echo '*** 正在 清理工程 ***'
    xcodebuild \
    clean -configuration ${development_mode}
    echo '*** 清理完成 ***'
}

#拷贝资源
copy_resource()
{
    src_res_path=$1
    res_name=$2
    show_name=$3

    echo "开始svn更新目录[$src_res_path]"
    cd $src_res_path
    svn up
    if [ $? != 0 ]
    then
    echo -e "ERROR!!svn更新失败">$param/temp.txt
    exit 1
    fi
    echo "svn更新完毕"

    echo "开始拷贝资源从${src_res_path} 拷贝到 ${g_dest_res_path}"
    rm -rf $g_dest_res_path
    mkdir $g_dest_res_path
    cp -R $src_res_path/* $g_dest_res_path
        if [ $? != 0 ]
        then
            echo "[$(date +%y%m%d_%H:%M:%S)]<<资源拷贝>>[$g_target_name]渠道: 资源[$res_name] 拷贝异常请注意检查,资源路径[$src_res_path]">$param/temp.txt
            exit 1
        fi

    echo "资源拷贝完毕"
}

#构建
build()
{
    cd $g_main_proj_directory

    OLD_IFS="$IFS"
    IFS=","
    arr_target=($g_target_name)
    arr_res_path=($g_res_path)
    num_target=${#arr_target[@]}
    num_res_path=${#arr_res_path[@]}

    echo "g_target_name=${g_target_name} num=$num_target "
    echo "g_res_name=${g_res_name}"
    echo "g_res_path=${g_res_path} num=$num_res_path"

    IFS="$OLD_IFS"
    if [ $num_res_path != $num_target ]
    then
        echo -e '打包参数个数不匹配'>$param/temp.txt
        exit 1
    fi

    for ((i=0;i<num_target;i++))
    do
        target_name=${arr_target[$i]}
        str_res_paths=${arr_res_path[$i]}
        IFS=":"
        arr_res_path_single_target=($str_res_paths)
        IFS="$OLD_IFS"
        num_res=${#arr_res_path_single_target[@]}

        for ((j=0;j<num_res;j++))
        do
            res_path=${arr_res_path_single_target[$j]}
            echo "一共需要生成的包[$g_target_name] ,当前正在生成的包名称[$target_name], 资源名称[$g_res_name],资源路径[$res_path] "
            # 资源拷贝
            # copy_resource $res_path $res_name $target_name

            echo '1.正在 编译工程 For '${development_mode}
            xcodebuild \
            archive -workspace ${g_main_proj_directory}/${target_name}.xcworkspace \
            -scheme ${target_name} \
            -configuration ${development_mode} \
            -archivePath ${g_build_path}/${target_name}.xcarchive 
            # xcodebuild \
            # archive -project ${g_main_proj_directory}/${target_name}.xcodeproj \
            # -scheme ${target_name} \
            # -configuration ${development_mode} \
            # -archivePath ${g_build_path}/${target_name}.xcarchive 


            if [ $? != 0 ]
            then
            echo "编译失败">$param/temp.txt
            exit 1
            fi
            echo '*** 编译完成 ***'


            echo "2. 开始打包ipa..."

            channelipaname="${exportFilePath}/$(date +%Y%m%d%H%M%S)_${target_name}_${g_res_name}"

            xcodebuild \
            -exportArchive -archivePath ${g_build_path}/${target_name}.xcarchive \
            -configuration ${development_mode} \
            -exportPath ${channelipaname} \
            -exportOptionsPlist ${exportOptionsPlistPath} 

            if [ $? != 0 ]
            then
            echo "创建.ipa文件失败">$param/temp.txt
            exit 1
            fi
               
             echo '*** .ipa文件已导出 ***'
        done
    done   

    exit 0
}

clear_mainproj
build 

exit 0
