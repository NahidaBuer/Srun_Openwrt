NAME="srun"

echo "正在关闭服务..."
service $NAME stop
service $NAME disable
echo "正在删除文件..."
result=$(rm /etc/config/$NAME /etc/init.d/$NAME /usr/bin/$NAME.sh)
if [ -z "$result" ]
then
    echo "卸载成功! "
else
    echo "请参考报错信息..."
fi
