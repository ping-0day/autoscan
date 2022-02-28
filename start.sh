#!/bin/bash
#资产更新
nuclei -silent -update
sleep 5
nuclei -silent -ut

echo "nuclei更新完毕开始资产收集" | notify -silent -provider telegram
#资产倒入
subfinder -silent -dL domain.txt -o domains.txt
echo "子域名收集完毕" | notify -silent -provider telegram
cat domains.txt >> newdomains.md
rm -f domain.txt
rm -f domains.txt
awk 'NR==FNR{lines[$0];next} !($0 in lines)' alltargets.txtls newdomains.md >> domains.txtls #资产对比
rm -f newdomains.md
################################################################################## 发送新增资产手机通知
sleep 10
echo "资产侦察结束 $(date +%F-%T),找到新域 $(wc -l < domains.txtls) 个" | notify -silent -provider telegram


##################################################################################
if [ -s domains.txtls ];then
        echo "开始使用 naabu 对新增资产端口扫描"  | notify -silent -provider telegram
        naabu -stats -l domains.txtls -p 80,81,82,83,84,85,86,87,88,89,90,443,6379,7001,7002,7003,8000,8001,8002,8003,8004,8005,8006,8007,8008,8009,8080,8081,8082,8083,8084,8085,8086,8087,8088,8089,8090,8443,8888,8889,8890,9080,9990,27017 -silent -o open-domain.txtls &> /dev/null
        echo "端口扫描结束，开始使用httpx探测存活"   | notify -silent -provider telegram
        httpx -silent -stats -l open-domain.txtls -fl 0 -mc 200,302,403,404,204,303,400,401 -o newurls.txtls &> /dev/null
        echo "httpx共找到存活资产 $(wc -l < newurls.txtls) 个" | notify -silent -provider telegram
        cat newurls.txtls >new-active-$(date +%F-%T).txt #保存新增资产记录

         cat domains.txtls >> alltargets.txtls

        echo "已将存活资产存在加入到历史缓存 $(date +%F-%T)" | notify -silent -provider telegram
        rm -f domains.txtls

#使用nuclei，xray 扫描存活资产，并将漏洞结果发送到通知，并删除此次缓存文件，并结束
        echo "开始使用 nuclei 对新增资产进行漏洞扫描" | notify -silent -provider telegram
        cat newurls.txtls | nuclei -rl 600 -bs 50 -c 30  -mhe 10 -ni -o res-all-vulnerability-results.txtls -stats -silent -severity critical,medium,high,low -es info |notify -silent -provider telegram

        sleep 5
        echo "nuclei漏洞扫描结束" | notify -silent -provider telegram
#xray 进行扫描
        echo "开始使用 xray 对新增资产进行漏洞扫描"  | notify -silent -provider telegram

        python3 /root/crawlergo_x_XRAY/launcher.py

        echo "crawlergo稍后查看"  | notify -silent -provider telegram
        rm -f open-domain.txtls
        rm -f newurls.txtls
else

################################################################################## Send result to notify if no new domains found

        echo "没有新域 $(date +%F-%T)"| notify -silent -provider telegram
fi