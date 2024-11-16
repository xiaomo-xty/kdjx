#!/bin/sh
# ===========================================配置文件替换和更=========================================================================

echo '====================替换IP==========='
# 获取环境变量中的 HOST_IP，或者使用默认值
HOST_IP=${HOST_IP:-"150.158.99.73"}  # 如果没有指定 HOST_IP，则使用默认的 150.158.99.73

# 输出当前正在使用的 IP 地址
echo "Using new IP: ${HOST_IP}"

# 检查是否存在保存的旧 IP 地址文件
if [ -f /mnt/pokemon/ip_address.txt ]; then
    OLD_IP=$(cat /mnt/pokemon/ip_address.txt)
else
    OLD_IP="150.158.99.73"  # 默认旧 IP 为 150.158.99.73
fi

# 输出当前保存的旧 IP 地址
echo "Current saved IP: ${OLD_IP}"

# 如果新的 HOST_IP 与当前保存的旧 IP 不同，才执行替换
if [ "$HOST_IP" != "$OLD_IP" ]; then
    echo "Replacing $OLD_IP with ${HOST_IP}"

    # 替换配置文件中的旧 IP 地址为新的 HOST_IP
    sed -i "s/$OLD_IP/${HOST_IP}/g" /www/wwwroot/game/pokemon/patch/1022/res/version.plist
    sed -i "s/$OLD_IP/${HOST_IP}/g" /mnt/pokemon/release/login/conf/dev/serv.json
    sed -i "s/$OLD_IP/${HOST_IP}/g" /mnt/pokemon/release/login/conf/serv.json
    sed -i "s/$OLD_IP/${HOST_IP}/g" /mnt/pokemon/release/login/defines.json
    sed -i "s/$OLD_IP/${HOST_IP}/g" /mnt/pokemon/release/game_defines.py
    sed -i "s/$OLD_IP/${HOST_IP}/g" /mnt/pokemon/release/payment_defines.py

    # 保存新的 HOST_IP，供下一次启动时使用
    echo "${HOST_IP}" > /mnt/pokemon/ip_address.txt
else
    echo "No replacement needed. ${HOST_IP} is already the current IP."
fi

echo '====================更新版本信息======================'

# 更新版本信息
VERSION_MD5=$(md5sum /www/wwwroot/game/pokemon/patch/1022/res/version.plist | awk '{ print $1 }')
VERSION_SIZE=$(stat -c %s /www/wwwroot/game/pokemon/patch/1022/res/version.plist)
jq --arg size "$VERSION_SIZE" --arg md5 "$VERSION_MD5" \
    '( .files[] | select(.name == "res/version.plist") ) |= . + {size: ($size | tonumber), md5: $md5}' \
    /mnt/pokemon/release/login/patch/cn/1022.json > temp.json && mv temp.json /mnt/pokemon/release/login/patch/cn/1022.json

head -n 10 /mnt/pokemon/release/login/patch/cn/1022.json
# ===========================================配置文件替换和更新========================================================================


# ==========================其他服务器配置修改======================
# 区名修改
jq --arg newName "$SERVER_NAME" '.[0].name = $newName' /mnt/pokemon/release/login/conf/serv.json > /tmp/serv_modified.json
mv /tmp/serv_modified.json /mnt/pokemon/release/login/conf/serv.json

# 公告更新，可以写一个文件读进来，覆盖原有公告

# ================================================================


# ====================================================开启网站========================================================================
# - /usr/local/game.conf 由主机提供

# 修改主机IP
cp /usr/local/game.conf /etc/nginx/sites-available/game.conf
sed -i "s/HOST_IP/${HOST_IP}/g" /etc/nginx/sites-available/game.conf
cat /etc/nginx/sites-available/game.conf
# 创建符号链接，启用该配置
ln -sf /etc/nginx/sites-available/game.conf /etc/nginx/sites-enabled/
# 检查 Nginx 配置文件的语法是否正确
nginx -t

# 启动 PHP-FPM，以前台模式运行并放到后台
/usr/local/php/sbin/php-fpm -F &

# 启动 Nginx 服务器
nginx -g "daemon off;" &

# =====================================================开启网站========================================================================



# =====================================================启动游戏服务器========================================================================
cd /mnt/pokemon/deploy_dev
rm supervisor.sock
supervisord -c supervisord.conf
supervisorctl start all
supervisorctl status
# =====================================================启动游戏服务器========================================================================

wait



