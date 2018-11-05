#!/bin/bash

HADOOP_HOME="/opt/hadoop"
HADOOP_DATA="/var/lib/hadoop"

SPARK_HOME="/opt/spark"

SLAVE_COUNT=10

# Prepare list of slave IPs
SLAVE_LIST=""

counter=1
until [[ ${counter} -gt ${SLAVE_COUNT} ]]
do
    SLAVE_LIST=${SLAVE_LIST}"10.1.1.$((counter + 10 - 1))"$'\n'
    ((counter++))
done

# Update packages and install java package
yum update -y -q
yum install java-1.8.0-openjdk -y -q

# Configure environment variables
export JAVA_HOME="/usr/lib/jvm/jre"
export HADOOP_HOME="$HADOOP_HOME"
export HADOOP_INSTALL="$HADOOP_HOME"
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_HOME"
export HADOOP_YARN_HOME="$HADOOP_HOME"
export HADOOP_COMMON_LIB_NATIVE_DIR="$HADOOP_HOME/lib/native"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export YARN_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_USER_NAME=hadoop
export SPARK_HOME="$SPARK_HOME"
export PATH="$PATH:$HADOOP_HOME/bin:$SPARK_HOME/bin"

echo "
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME
export HADOOP_INSTALL=$HADOOP_INSTALL
export HADOOP_COMMON_HOME=$HADOOP_COMMON_HOME
export HADOOP_HDFS_HOME=$HADOOP_HDFS_HOME
export HADOOP_YARN_HOME=$HADOOP_YARN_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_COMMON_LIB_NATIVE_DIR
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export YARN_CONF_DIR=$YARN_CONF_DIR
export HADOOP_USER_NAME=hadoop
export SPARK_HOME=$SPARK_HOME
export PATH=$PATH
" > /etc/profile.d/hadoop-spark-env.sh

# Download, install and configure Hadoop
wget -q http://mirrors.advancedhosters.com/apache/hadoop/common/hadoop-3.0.3/hadoop-3.0.3.tar.gz

tar -xzf hadoop-3.0.3.tar.gz

mv hadoop-3.0.3 "$HADOOP_HOME"

mkdir "$HADOOP_DATA"
mkdir "$HADOOP_DATA/hdfs"
mkdir "$HADOOP_DATA/hdfs/namenode"
mkdir "$HADOOP_DATA/hdfs/datanode"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://ip-10-1-1-100.ec2.internal:9000</value>
    </property>
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
    </property>
</configuration>" > "$HADOOP_CONF_DIR/core-site.xml"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<configuration>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/var/lib/hadoop/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/var/lib/hadoop/hdfs/datanode</value>
    </property>
    <property>
        <name>dfs.blocksize</name>
        <value>134217728</value>
    </property>
    <property>
        <name>dfs.namenode.handler.count</name>
        <value>100</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
</configuration>" > "$HADOOP_CONF_DIR/hdfs-site.xml"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<configuration>
    <property>
        <name>yarn.acl.enable</name>
        <value>0</value>
    </property>
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>0</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>ip-10-1-1-100.ec2.internal</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler</value>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>128</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>1536</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>1536</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>3</value>
     </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
     </property>
</configuration>" > "$HADOOP_CONF_DIR/yarn-site.xml"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.resource.mb</name>
        <value>512</value>
    </property>
    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>256</value>
    </property>
    <property>
        <name>mapreduce.map.java.opts</name>
        <value>-Xmx1024M</value>
    </property>
    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>256</value>
    </property>
    <property>
        <name>mapreduce.reduce.java.opts</name>
        <value>-Xmx1024M</value>
    </property>
    <property>
        <name>mapreduce.task.io.sort.mb</name>
        <value>128</value>
    </property>
    <property>
        <name>mapreduce.task.io.sort.factor</name>
        <value>50</value>
    </property>
    <property>
        <name>mapreduce.reduce.shuffle.parallelcopies</name>
        <value>25</value>
    </property>
</configuration>" > "$HADOOP_CONF_DIR/mapred-site.xml"

echo "
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOP_HOME

export HADOOP_OS_TYPE=\${HADOOP_OS_TYPE:-\$(uname -s)}

case \${HADOOP_OS_TYPE} in
  Darwin*)
    export HADOOP_OPTS=\"\${HADOOP_OPTS} -Djava.security.krb5.realm= \"
    export HADOOP_OPTS=\"\${HADOOP_OPTS} -Djava.security.krb5.kdc= \"
    export HADOOP_OPTS=\"\${HADOOP_OPTS} -Djava.security.krb5.conf= \"
  ;;
esac
" > "$HADOOP_CONF_DIR/hadoop-env.sh"

echo "$SLAVE_LIST" > "$HADOOP_CONF_DIR/workers"

useradd -d "$HADOOP_HOME" -M hadoop

chown -R hadoop: "$HADOOP_HOME"
chown -R hadoop: "$HADOOP_DATA"
chmod 0755 "$HADOOP_HOME"

# Create Hadoop SSH keys
mkdir "$HADOOP_HOME/.ssh"

echo "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAtfSZAYjXm6yUbIN18+1HjG2bAwC9z2VCnUF/07eTykuVVsUd
5EvRXGYCX69yRaY66Oz2+cxh8GmMfeRECuJKaWYqPThDdIGNkh7IxRn19rWUgiwa
QFLIXUrWawwdXplnG4mvA/r06d1ymS9X2LvZdZcoz1UZq8MEJ/uJUffFnnQAKCmx
ZtkPHiW1LEXIZrrFhgokKUrJLVT/r1rCdSAYA6yQsNj6ZR5GaK7zETQOrMlW0TLL
FbjIviYhvl7phoNDlJKpx4OoaKTIf+/b66MI9BuoMj90ptHve6wFn++DWaV7xJdv
BiqcNX/w0j5O7uodprsuiStOJ2DlGnu/bJnZVwIDAQABAoIBAH6YMIA10jTYbOfW
yxEsjHQyqf/72xPZ0vAQazxFZEkCL2QQfwygh4hu3MXwDmRRFHmMrQT9Y0LeXMYW
NBUSfk04rLitVZlQrcv1KSChQFUm3q12u8j3D7qA4A/YfPKdbnRlZeQyDYZM8XeM
zeTYRaMfyV//SH4Nj+21f0QNTGxCAOiO7PDiWPxE8hsQbuR5HRzUpD1c4uc+8QD1
7MbOIfGy79wf0noR/8SskzmjnAOX5c/l1DAujJjXkLku3/iN2vJC3WekoyWec2T1
FM53c3ThfQ29+rO0D5XdJTao0IY7eJER7ZB1EIo5xfqjBYkAhdRK/IV9jREGPAhJ
kiYWRtECgYEA8H4cbw7X+9yRAv2r1z/KFje8ng6Jm9Yj1mmgx7YBd6Mpw3uMVacL
/fsHWlMBfdKz5RTCsSuBOtTmUP0oP/4DA+rbG7H7WaBZ+ogDqJhWj13alBrN1CeM
ZDnad8ZeyV4Yn+os+nkTW14hck8jLDAjlhCxqDS9+R1RKIk+p8IleTkCgYEAwbAx
4+1pwat4Cbo2Ml0rb62aZVgs6/F6C8fLuPPvUicGldr+VJeCTtvRjyzAbrtlW4ES
vSMGaDa9BlQsPbTG8rSmOahPQV4+dVqgeBfYqsRqiR3vFXx8/X5qleKauBcd8obX
uCEqzurzTYYuxLFM9M3bTWiFR7UdJLp7+hjAtw8CgYBVaMRaYNAt/5B0mnir8lin
+VWAYLNYZ/3ESTEznBz7SzQq27bkOHZW1g8vcelGsUz4X54hY8z6gt/lBXOE/oY9
nuv/8v7MPtmV0zZRawDa278j+Dz/Sqhec/l1rjq9kzB1oqokrllEirKgMSDRsasB
wZ4GmeyaC2JmXg+lbpr2aQKBgQCUYQR3VgN0qIVW/l5Siumhrl7fUINpZR5YNAEv
eUBXsSnsV04LQ95Bx0hs5J2utsTZKrJOTqyz3WtFk+oog3r9p8LH3NaKf0Zd5MWV
+r6zY7ExxcrIrQubruK8XFKmwJ7iksZjepUu2vL06tydNi58Q8/DJ1UjL+5Zmrsr
RxcrpQKBgQCPpgLWZE0VeNnaUE9NiIrnmgy9Rmf7vDI3hfNFELtXbgvF1u5F4DYc
fz67BWjCLyx3mpA910GYujHTaXjiKR1MWTboJwMkhHEaaH+xKXnmSDlVOxMtbUGq
Rsqqe4H9GfE86axqtywsAwzCZjqhO4jbskSVeVTWzjpgx1eb3t7W4A==
-----END RSA PRIVATE KEY-----
" > "$HADOOP_HOME/.ssh/id_rsa"

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC19JkBiNebrJRsg3Xz7UeMbZsDAL3PZUKdQX/Tt5PKS5VWxR3kS9FcZgJfr3JFpjro7Pb5zGHwaYx95EQK4kppZio9OEN0gY2SHsjFGfX2tZSCLBpAUshdStZrDB1emWcbia8D+vTp3XKZL1fYu9l1lyjPVRmrwwQn+4lR98WedAAoKbFm2Q8eJbUsRchmusWGCiQpSsktVP+vWsJ1IBgDrJCw2PplHkZorvMRNA6syVbRMssVuMi+JiG+XumGg0OUkqnHg6hopMh/79vrowj0G6gyP3Sm0e97rAWf74NZpXvEl28GKpw1f/DSPk7u6h2muy6JK04nYOUae79smdlX hadoop" > "$HADOOP_HOME/.ssh/id_rsa.pub"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC19JkBiNebrJRsg3Xz7UeMbZsDAL3PZUKdQX/Tt5PKS5VWxR3kS9FcZgJfr3JFpjro7Pb5zGHwaYx95EQK4kppZio9OEN0gY2SHsjFGfX2tZSCLBpAUshdStZrDB1emWcbia8D+vTp3XKZL1fYu9l1lyjPVRmrwwQn+4lR98WedAAoKbFm2Q8eJbUsRchmusWGCiQpSsktVP+vWsJ1IBgDrJCw2PplHkZorvMRNA6syVbRMssVuMi+JiG+XumGg0OUkqnHg6hopMh/79vrowj0G6gyP3Sm0e97rAWf74NZpXvEl28GKpw1f/DSPk7u6h2muy6JK04nYOUae79smdlX hadoop" > "$HADOOP_HOME/.ssh/authorized_keys"

chown -R hadoop: "$HADOOP_HOME/.ssh"
chmod 0700 "$HADOOP_HOME/.ssh"
chmod 0600 "$HADOOP_HOME/.ssh/id_rsa"
chmod 0600 "$HADOOP_HOME/.ssh/id_rsa.pub"
chmod 0600 "$HADOOP_HOME/.ssh/authorized_keys"

# Download, install and configure Hadoop
wget -q https://archive.apache.org/dist/spark/spark-2.3.2/spark-2.3.2-bin-hadoop2.7.tgz

tar -xvf spark-2.3.2-bin-hadoop2.7.tgz

mv spark-2.3.2-bin-hadoop2.7 "$SPARK_HOME"

echo "#!/usr/bin/env bash

export SPARK_MASTER_HOST=ip-10-1-1-100.ec2.internal
" > "$SPARK_HOME/conf/spark-env.sh"

chmod 0775 "$SPARK_HOME/conf/spark-env.sh"

echo "$SLAVE_LIST" > "$SPARK_HOME/conf/slaves"

chmod 0664 "$SPARK_HOME/conf/slaves"

useradd -d "$SPARK_HOME" -M spark

chown -R spark: "$SPARK_HOME"
chmod 0755 "$SPARK_HOME"

# Create Spark SSH keys
mkdir "$SPARK_HOME/.ssh"

echo "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAuXEuPQxgGz5rSCzKc1Jdxut2rATsXQiP5m+WcUxVQiuLs2Y9
Hxo2IgMauYmizmMld6WydFpAKsRGZXByWSBn2Yksn4hUW5K+rOgDgbrKi/WiBJkY
EfG5qLEmOBEj8tT2q1+urnKSpSL/K9yaTq9MugIZTVdVMGDbCfz5ibP3tDTLb44H
26AGPqCd3xDdGr5LkUod8rlluaxN5dHjmB6jyBj3yWk+8cDqgP+zYZNhtEG+EjH5
Y9RoJC5JBYn0kAiJkPCLhcHb5+hQKeXp4ZiJ6osWgXd1kEdAA1YLZyfwuDZc2v7X
lql5u0EDJtP8qK3EhPmHXjRgMnpEPchwYR49sQIDAQABAoIBAF5N4GXLVVSFealK
nenniSkPtVnlZw4ovIVDWg5j8zejTXf+Fjcq7Tx+t6iDBfhPE061RPtGqjsVdXdA
p+YLRMSrrbWzbrLi/XSQyLfAdiCW2b3c3RDDDNdsvzLkBJQJGSgtkHfGbCzujzWP
CinZm/s79gIO15OyrbF2pLAShXVuRUSAdGdDti3eZCsV/6crwTwOFZCBxpdkHTHc
Cktjcm37CebOKxHOaN3iuo32Y0TOJlIX83qm7ehu+RBXEVHMPYbnxgVZc57vL+Nq
7+xA+UoSOk0K1CuTmgGbVwAurMqzWIlu4Y0jDf5qwWFR9Ow/cpuWOehWQHVExjVJ
RwrRDcECgYEA7m9+5PIGQ+5whBnwtb+3jKdDP8yhL1yR8QA9O8viFCqgLhbF/NCC
IhIKNBNO04bMz3A7oRBQx9yIJsjPSwJj/LifdGc2l9cM9KmmNqgJ/RcVvnNz8NEU
P3n1aXbhuOAjuFmcprDyu7GSqRiG0BG7PPfhN7e0yO1k2V0Fv83NdJsCgYEAxxpQ
0b1LXmI4EtCZnneTCFkiI5kSgSOgaUOHKoGH6k3aL9AxzrouuVhhF7ItkE3Eu0I8
mc/PBU7sizLlayzRC4fG2g9ucD7Mvcz6W+ksbv/cDfOsfwtWWrR5ZGZ1zbWo7Iyi
IynDzp4zFcD40SqELKS/Kqsq2HDrLLyCUYrlbaMCgYEA1er2YBW8BUpxbDORwJ5G
4UxXi2/d1Q4qaZybU4CyTwGHQJJyA0ZW2pZwzRPdju3L5vh8px5qO0XiaVmUkWmN
p3lEpjzLwCLSntduJm9Qtt71RS9z/8S1c9XJlltwXFvL8GOFpg/vVvIT8N3uZdLi
t+p1B3YsHnDOIC3TMKhGAq0CgYEAntGSCEw785Tbb76v22U8hts6zTSMOzDlAzKX
fkOG3FKvqZYkNOf032ntQQ6jI8m1FT53wqWuWGilbT/zGvPL6Kus5kKK8MRXY0s/
pdMw23YC3aozPcAYaRAvCPRmIeo3TkG8D9p/07ADxeWBVK/acRYVW37gFXi1T6Er
PspRyosCgYBPd3HpXk+JI3eBxSjBNi8Ek8xmH4Ep6H0MjiJS4vQDLEOcsJkVzp0V
UUi5XtvF/f/xTv3xWD04sNga06c1WL68XR4jSf4MFmcFqt6zW/A5WiTKExvEYi+6
7trN7FdjpyoQznO8uhAPETirKppdLYepxWEYcNUT8spC88DmFPeQuQ==
-----END RSA PRIVATE KEY-----
" > "$SPARK_HOME/.ssh/id_rsa"

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5cS49DGAbPmtILMpzUl3G63asBOxdCI/mb5ZxTFVCK4uzZj0fGjYiAxq5iaLOYyV3pbJ0WkAqxEZlcHJZIGfZiSyfiFRbkr6s6AOBusqL9aIEmRgR8bmosSY4ESPy1ParX66ucpKlIv8r3JpOr0y6AhlNV1UwYNsJ/PmJs/e0NMtvjgfboAY+oJ3fEN0avkuRSh3yuWW5rE3l0eOYHqPIGPfJaT7xwOqA/7Nhk2G0Qb4SMflj1GgkLkkFifSQCImQ8IuFwdvn6FAp5enhmInqixaBd3WQR0ADVgtnJ/C4Nlza/teWqXm7QQMm0/yorcSE+YdeNGAyekQ9yHBhHj2x spark" > "$SPARK_HOME/.ssh/id_rsa.pub"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5cS49DGAbPmtILMpzUl3G63asBOxdCI/mb5ZxTFVCK4uzZj0fGjYiAxq5iaLOYyV3pbJ0WkAqxEZlcHJZIGfZiSyfiFRbkr6s6AOBusqL9aIEmRgR8bmosSY4ESPy1ParX66ucpKlIv8r3JpOr0y6AhlNV1UwYNsJ/PmJs/e0NMtvjgfboAY+oJ3fEN0avkuRSh3yuWW5rE3l0eOYHqPIGPfJaT7xwOqA/7Nhk2G0Qb4SMflj1GgkLkkFifSQCImQ8IuFwdvn6FAp5enhmInqixaBd3WQR0ADVgtnJ/C4Nlza/teWqXm7QQMm0/yorcSE+YdeNGAyekQ9yHBhHj2x spark" > "$SPARK_HOME/.ssh/authorized_keys"

chown -R spark: "$SPARK_HOME/.ssh"
chmod 0700 "$SPARK_HOME/.ssh"
chmod 0600 "$SPARK_HOME/.ssh/id_rsa"
chmod 0600 "$SPARK_HOME/.ssh/id_rsa.pub"
chmod 0600 "$SPARK_HOME/.ssh/authorized_keys"