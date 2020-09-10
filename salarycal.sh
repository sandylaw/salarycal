#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-29
function is_number() {
    echo "$1" | sed 's/\.\|-\|+\|%\|\^//g' | grep "[^0-9]" > /dev/null && echo 0 || echo 1
}

function cal_stop_day_num(){
    stop_day_day=$1
    stop_month_workday=$2

if echo "$stop_month_workday"|grep -q -w "$stop_day_day";then
    your_stop_month_wrokday_num=$(($(echo $stop_month_workday|tr " " "\n"|sed '/^[ ]*'"$stop_day_day"'/,$d'|wc -l)+1))
else
    stop_day_day=$((stop_day_day-1))
    if [ "$stop_day_day" == 1 ];then
        echo "Please check you input"
        read_workday_start_stop
    fi
    cal_stop_day_num "$stop_day_day" "$stop_month_workday"
fi
}

function read_workday_start_stop(){
    echo "In this month，When did you start to work?"
    echo "The first day of attendance/考勤第一天/第一天上班的日期"
    read -rp "Please input your first workday/请输入你的第一个工作日[2020-06-10]: " start_day
    if [ -z "$start_day" ];then
        echo "Please check your input."
        read_workday_start_stop
    fi

    if echo "$start_day" | grep -Eq "[0-9]{4}-[0-9]{2}-[0-9]{2}" && date -d "$start_day" +%Y%m%d > /dev/null 2>&1; then 
        :
    else
        echo "Please check your input."
        echo "输入的日期格式不正确，应为yyyy-mm-dd"
        read_workday_start_stop
    fi

    echo "In this month，When did you done your work?"
    echo "Last day of attendance/考勤最后一天"
    read -rp "Please input your last workday/请输入你最后一个工作日[2020-06-22]: " stop_day
    if [ -z "$stop_day" ];then
        echo "Please check your input."
        read_workday_start_stop
    fi

    if echo "$stop_day" | grep -Eq "[0-9]{4}-[0-9]{2}-[0-9]{2}" && date -d "$stop_day" +%Y%m%d > /dev/null 2>&1; then 
        :
    else
        echo "Please check your input."
        echo "输入的日期格式不正确，应为yyyy-mm-dd"
        read_workday_start_stop
    fi
}
function cal_workday(){
    start_day=$1
    stop_day=$2

    start_day_year=$(echo "$start_day" | awk -F "-" '{print $1}')
    start_day_month=$(echo "$start_day" | awk -F "-" '{print $2}')
    start_day_day=$(echo "$start_day" | awk -F "-" '{print $3}')
    if [[ $(echo $start_day_day |cut -b -1) == 0 ]] ;then
	 start_day_day=$(echo $start_day_day |cut -b 2)
    fi

    start_month_workday=$(ncal "$start_day_month" "$start_day_year" -h | grep -vE "^ |^$" | sed "s/[[:alpha:]]//g" | head -n -2 | fmt -w 1 | sort -n)

    if echo "$start_month_workday"|grep -q -w "$start_day_day";then
        your_start_month_wrokday_num=$(echo $start_month_workday|tr " " "\n"|sed '/^[ ]*'"$start_day_day"'/,$!d'|wc -l)
    else
        echo "Please check your input"
        echo "The "$start_day_day" is not workday."
        read_workday_start_stop
        cal_workday "$start_day" "$stop_day"
    fi


    stop_day_year=$(echo "$stop_day" | awk -F "-" '{print $1}')
    stop_day_month=$(echo "$stop_day" | awk -F "-" '{print $2}')
    stop_day_day=$(echo "$stop_day" | awk -F "-" '{print $3}')
    stop_month_workday=$(ncal "$stop_day_month" "$stop_day_year" -h | grep -vE "^ |^$" | sed "s/[[:alpha:]]//g" | head -n -2 | fmt -w 1 | sort -n)

    interval_month=$((10#$stop_day_month-10#$start_day_month))
    if [ "$interval_month" == 0 ];then
        result_work_day_num=$(($(echo $stop_month_workday|tr " " "\n"|sed '/^[ ]*'"$start_day_day"'/,$!d'|sed '/^[ ]*'"$stop_day_day"'/,$d'|wc -l)+1))

    elif [ "$interval_month" == 1 ] ;then
        cal_stop_day_num "$stop_day_day" "$stop_month_workday"

        result_work_day_num=$((your_start_month_wrokday_num+your_stop_month_wrokday_num))
    else
        echo  "Please check your input."
        read_workday_start_stop
        cal_workday "$start_day" "$stop_day"
    fi

    read -rp "This month, how many holidays ? default 0: " holiday
    if [ -z "$holiday" ]; then
        holiday=0
    fi
    isnumber=$(is_number "$holiday")
    if [ "$isnumber" == 1 ] && [ "$holiday" -ge 0 ] && [ "$holiday" -le 14 ]; then
        :
    else
        echo "Please check your input."
        read_workday_start_stop
        cal_workday "$start_day" "$stop_day"
    fi
    
    
    case "$fm_yesno" in
    yes|y|Y|YES)
        # if [ "$interval_month" == 0 ];then
        #     #不跨月的新人，日历工作天数
        #     cal_stop_day_num "$stop_day_day" "$stop_month_workday"
        #     calendar_work_day="$your_stop_month_wrokday_num"

        #  elif [ "$interval_month" == 1 ] && [ "$start_day_day" -gt "$stop_day_day" ];then
            #新人，日历工作天数
            calendar_start_month_wrokday_num=$(echo $start_month_workday|tr " " "\n"|sed '/^[ ]*'"$stop_day_day"'/,$!d'|wc -l)
            cal_stop_day_num "$stop_day_day" "$stop_month_workday"
            calendar_work_day=$((calendar_start_month_wrokday_num+your_stop_month_wrokday_num))
        # else
        #     echo  "Please check your input."
        #     read_workday_start_stop
        #     cal_workday "$start_day" "$stop_day"
        # fi
        ;;
    *)
        ;;
    esac 

    work_day=$((result_work_day_num - holiday))
    calendar_work_day=$((calendar_work_day - holiday))

}
function get_insurance_base() {
    wage_basic=$1
    wage_job=$2
    bonus=$3
    standard_income=$(echo "scale=2;$wage_basic+$wage_job+$bonus" | bc)
    echo "社保基数和公积金基数"
    read -rp "The insurance and house fund base number is $(echo "scale=2;$standard_income/2" | bc)  and house fund base number is $(echo "scale=2;$standard_income" | bc)? yes or no: " YesNo
    case $YesNo in
        yes | y | Y | YES)
            life_base=$(echo "scale=2;$standard_income/2" | bc)
            unemployment_base=$(echo "scale=2;$standard_income/2" | bc)
            workinjury_base=$(echo "scale=2;$standard_income/2" | bc)
            maternity_base=$(echo "scale=2;$standard_income/2" | bc)
            medical_base=$(echo "scale=2;$standard_income/2" | bc)
            house_fund_base=$(echo "scale=2;$standard_income" | bc)
            ;;
        *)
            echo "社保基数和公积金基数"
            read -rp "The insurance and house fund base number is $standard_income ? yes or no: " YesNo
            case $YesNo in
                yes | y | Y | YES)
                    life_base="$standard_income" #养老保险
                    unemployment_base="$standard_income" #失业保险
                    workinjury_base="$standard_income" #工伤保险
                    maternity_base="$standard_income" #生育保险
                    medical_base="$standard_income" #医疗保险
                    house_fund_base="$standard_income" #住房公积金
                    ;;
                *)
                    echo "养老保险基数"
                    read -rp "Please input the Life Insurance Base:" life_base
                    if [ -z "$life_base" ]; then
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    isnumber=$(is_number "$life_base")
                    if [ "$isnumber" == 1 ] && [ "$(echo "$life_base > 0 " | bc)" == 1 ] && [ "$(echo "$life_base  <= 1000000" | bc)" == 1 ]; then
                        :
                    else
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    echo "失业保险基数"
                    read -rp "Please input the Unemployment Insurance Base:" unemployment_base
                    if [ -z "$unemployment_base" ]; then
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    isnumber=$(is_number "$unemployment_base")
                    if [ "$isnumber" == 1 ] && [ "$(echo "$unemployment_base > 0 " | bc)" == 1 ] && [ "$(echo "$unemployment_base  <= 1000000" | bc)" == 1 ]; then
                        :
                    else
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    echo "工伤保险基数"
                    read -rp "Please input the Base of Work Injury Insurance:" workinjury_base
                    if [ -z "$workinjury_base" ]; then
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    isnumber=$(is_number "$workinjury_base")
                    if [ "$isnumber" == 1 ] && [ "$(echo "$workinjury_base > 0 " | bc)" == 1 ] && [ "$(echo "$workinjury_base  <= 1000000" | bc)" == 1 ]; then
                        :
                    else
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    echo "生育保险基数"
                    read -rp "Please input the Maternity insurance base:" maternity_base
                    if [ -z "$maternity_base" ]; then
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    isnumber=$(is_number "$maternity_base")
                    if [ "$isnumber" == 1 ] && [ "$(echo "$maternity_base > 0 " | bc)" == 1 ] && [ "$(echo "$maternity_base  <= 1000000" | bc)" == 1 ]; then
                        :
                    else
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    echo "医疗保险基数"
                    read -rp "Please input the Medical insurance base:" medical_base
                    if [ -z "$medical_base" ]; then
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    isnumber=$(is_number "$medical_base")
                    if [ "$isnumber" == 1 ] && [ "$(echo "$medical_base > 0 " | bc)" == 1 ] && [ "$(echo "$medical_base  <= 1000000" | bc)" == 1 ]; then
                        :
                    else
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    echo "住房公积金基数"
                    read -rp "Please input the Housing Provident Fund Base:" house_fund_base
                    if [ -z "$house_fund_base" ]; then
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi
                    isnumber=$(is_number "$house_fund_base")
                    if [ "$isnumber" == 1 ] && [ "$(echo "$house_fund_base > 0 " | bc)" == 1 ] && [ "$(echo "$house_fund_base  <= 1000000" | bc)" == 1 ]; then
                        :
                    else
                        echo "Please check your input."
                        get_insurance_base "$@"
                    fi

                    ;;

            esac

            ;;

    esac

    # "$life_base" "$life_rate_corp" "$life_rate_per" "$unemployment_base"
    # "$unemployment_rate_corp" "$unemployment_rate_per" "$workinjury_base"
    # "$workinjury_rate_corp" "$maternity_base" "$maternity_rate_corp" "$maternity_rate_per"
    # "$medical_base" "$medical_rate_corp" "$medical_rate_per" "$house_fund_base"
    # "$house_fund_rate_corp" "$house_fund_rate_per"

}
function get_insurance_rate() {
    echo "
    2020年2-6月北京具体减免险种及比例

    1、单位养老保险比例：由16%下调至0%；

    2、单位失业保险比例：由0.8%下调至0%；

    3、单位工伤保险比例：由0.4%下调至0%；

    4、单位医疗保险比例：由10%下调至5%；

    5、单位生育保险比例：由0.8%下调至0.4%；

    2020年7-12月北京具体减免险种及比例：

    1、单位养老保险比例调整：由16%下调至0%；

    2、单位失业保险比例调整：由0.8%下调至0%；

    3、单位工伤保险比例调整：由0.4%下调至0%；   
    
    
    "
    echo "养老保险费率"
    read -rp "Please input the Life Insurance rate by company,default 16: " life_rate_corp
    if [ -z "$life_rate_corp" ]; then
        life_rate_corp=16
    fi
    isnumber=$(is_number "$life_rate_corp")
    if [ "$isnumber" == 1 ] && [ "$(echo "$life_rate_corp >= 0 " | bc)" == 1 ] && [ "$(echo "$life_rate_corp  <= 20" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi
    read -rp "Please input the Life Insurance rate by personal,default 8: " life_rate_per
    if [ -z "$life_rate_per" ]; then
        life_rate_per=8
    fi
    isnumber=$(is_number "$life_rate_per")
    if [ "$isnumber" == 1 ] && [ "$(echo "$life_rate_per >= 0 " | bc)" == 1 ] && [ "$(echo "$life_rate_per  <= 10" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi

    echo "失业保险费率"
    read -rp "Please input the Unemployment Insurance rate by company,default 0.8: " unemployment_rate_corp
    if [ -z "$unemployment_rate_corp" ]; then
        unemployment_rate_corp=0.8
    fi
    isnumber=$(is_number "$unemployment_rate_corp")
    if [ "$isnumber" == 1 ] && [ "$(echo "$unemployment_rate_corp >= 0 " | bc)" == 1 ] && [ "$(echo "$unemployment_rate_corp  <= 1" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi
    read -rp "Please input the Unemployment Insurance rate by personal,default 0.2: " unemployment_rate_per
    if [ -z "$unemployment_rate_per" ]; then
        unemployment_rate_per=0.2
    fi
    isnumber=$(is_number "$unemployment_rate_per")
    if [ "$isnumber" == 1 ] && [ "$(echo "$unemployment_rate_per >= 0 " | bc)" == 1 ] && [ "$(echo "$unemployment_rate_per  <= 0.5" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi

    echo "工伤保险费率"
    read -rp "Please input the rate of Work Injury Insurance by company,default 0.4: " workinjury_rate_corp
    if [ -z "$workinjury_rate_corp" ]; then
        workinjury_rate_corp=0.4
    fi
    isnumber=$(is_number "$workinjury_rate_corp")
    if [ "$isnumber" == 1 ] && [ "$(echo "$workinjury_rate_corp >= 0 " | bc)" == 1 ] && [ "$(echo "$workinjury_rate_corp  <= 1" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi

    echo "生育保险费率"
    read -rp "Please input the Maternity insurance  rate by company,default 0.8:" maternity_rate_corp
    if  [ -z "$maternity_rate_corp" ]; then
        maternity_rate_corp=0.8
    fi
    isnumber=$(is_number "$maternity_rate_corp")
    if [ "$isnumber" == 1 ] && [ "$(echo "$maternity_rate_corp >= 0 " | bc)" == 1 ] && [ "$(echo "$maternity_rate_corp  <= 1" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_base "$@"
    fi

    echo "医疗保险费率"
    read -rp "Please input the Medical insurance rate by company,default 10:" medical_rate_corp
    if [ -z "$medical_rate_corp" ]; then
        medical_rate_corp=10
    fi
    isnumber=$(is_number "$medical_rate_corp")
    if [ "$isnumber" == 1 ] && [ "$(echo "$medical_rate_corp >= 0 " | bc)" == 1 ] && [ "$(echo "$medical_rate_corp  <= 10" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi
    read -rp "Please input the Medical insurance rate by personal,default 2: " medical_rate_per
    if [ -z "$medical_rate_per" ]; then
        medical_rate_per=2
    fi
    isnumber=$(is_number "$medical_rate_per")
    if [ "$isnumber" == 1 ] && [ "$(echo "$medical_rate_per >= 0 " | bc)" == 1 ] && [ "$(echo "$medical_rate_per  <= 3" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi
    echo "住房公积金比例"
    read -rp "Please input the Housing Provident Fund rate by company,default 12: " house_fund_rate_corp
    if [ -z "$house_fund_rate_corp" ]; then
        house_fund_rate_corp=12
    fi
    isnumber=$(is_number "$house_fund_rate_corp")
    if [ "$isnumber" == 1 ] && [ "$(echo "$house_fund_rate_corp > 0 " | bc)" == 1 ] && [ "$(echo "$house_fund_rate_corp  <= 12" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi
    read     -rp "Please input the Housing Provident Fund rate by personal,default 12: " house_fund_rate_per
    if [ -z "$house_fund_rate_per" ]; then
        house_fund_rate_per=12
    fi
    isnumber=$(is_number "$house_fund_rate_per")
    if [ "$isnumber" == 1 ] && [ "$(echo "$house_fund_rate_per > 0 " | bc)" == 1 ] && [ "$(echo "$house_fund_rate_per  <= 12" | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        get_insurance_rate "$@"
    fi
}

function insurance() {
    #计算五险一金
    #养老保险
    life_base=$1
    life_rate_corp=$2
    life_rate_per=$3
    life_corp=$(echo "scale=2;$life_base*$life_rate_corp/100" | bc)
    life_per=$(echo "scale=2;$life_base*$life_rate_per/100" | bc)
    #失业保险
    unemployment_base=$4
    unemployment_rate_corp=$5
    unemployment_rate_per=$6
    unemployment_corp=$(echo "scale=2;$unemployment_base*$unemployment_rate_corp/100" | bc)
    unemployment_per=$(echo "scale=2;$unemployment_base*$unemployment_rate_per/100" | bc)
    #工伤保险,个人不交
    workinjury_base=$7
    workinjury_rate_corp=$8
    workinjury_corp=$(echo "scale=2;$workinjury_base*$workinjury_rate_corp/100" | bc)
    # 生育保险,个人不交
    maternity_base=$9
    maternity_rate_corp=${10}
    maternity_corp=$(echo "scale=2;$maternity_base*$maternity_rate_corp/100" | bc)

    #医疗保险
    medical_base=${11}
    medical_rate_corp=${12}
    medical_rate_per=${13}
    medical_corp=$(echo "scale=2;$medical_base*$medical_rate_corp/100" | bc)
    medical_per=$(echo "scale=2;$medical_base*$medical_rate_per/100" | bc)

    #计算五险合计数
    total_insurance_corp=$(echo "scale=2;$life_corp+$unemployment_corp+$workinjury_corp+$maternity_corp+$medical_corp" | bc)
    total_insurance_per=$(echo "scale=2;$life_per+$unemployment_per+$medical_per" | bc)

    #公积金基数
    house_fund_base=${14}
    house_fund_rate_corp=${15}
    house_fund_rate_per=${16}
    house_fund_corp=$(echo "scale=2;$house_fund_base*$house_fund_rate_corp/100" | bc)
    house_fund_per=$(echo "scale=2;$house_fund_base*$house_fund_rate_per/100" | bc)

}

function tax() {
    #工薪收入总额
    totalsalary=$1
    #专项附加扣除
    total_add_ded=$2
    base=5000
    worked_month=$3
    have_pay_tax=$4
    passed_out_tax_salary=$5
    total_in_tax_salary=$(echo "scale=2;$totalsalary - $total_add_ded - $base * $worked_month" | bc)
    if [ $(echo  "scale=2;$total_in_tax_salary <= 0" | bc) == 1 ]; then
        echo "INFO You don't need to pay taxes"
        need_pay_tax=0
        total_tax=0
    else
        echo "INFO Now begin cal your tax"
        isnumber=$(is_number "$total_in_tax_salary")
        if [ "$isnumber" == 1 ] && echo "$total_in_tax_salary > 0" | bc && echo "$total_in_tax_salary <= 36000" | bc; then
            tax_rate=3
            quick_ded=0
        elif [ "$isnumber" == 1 ] && echo "$total_in_tax_salary > 36000" | bc && echo "$total_in_tax_salary <= 144000" | bc; then
            tax_rate=10
            quick_ded=2520
        elif [ "$isnumber" == 1 ] && echo "$total_in_tax_salary > 144000" | bc && echo "$total_in_tax_salary <= 300000" | bc; then
            tax_rate=20
            quick_ded=16920
        elif [ "$isnumber" == 1 ] && echo "$total_in_tax_salary > 300000" | bc && echo"$total_in_tax_salary <= 420000" | bc; then
            tax_rate=25
            quick_ded=31920
        elif [ "$isnumber" == 1 ] && echo "$total_in_tax_salary > 420000" | bc && echo "$total_in_tax_salary <= 660000" | bc; then
            tax_rate=30
            quick_ded=52920
        elif [ "$isnumber" == 1 ] && echo "$total_in_tax_salary > 660000" | bc && echo "$total_in_tax_salary <=960000" | bc; then
            tax_rate=35
            quick_ded=85920
        elif [ "$isnumber" == 1 ] && echo "$total_in_tax_salary > 960000" | bc; then
            tax_rate=45
            quick_ded=181920
        fi
        total_tax=$(echo "scale=3;$total_in_tax_salary*$tax_rate/100 - $quick_ded" | bc)
        total_tax=$(echo "scale=2;($total_tax+0.005)/1.00" | bc)
        need_pay_tax=$(echo "$total_tax-$have_pay_tax" | bc)
    fi
    #累计应纳税额-已纳税额=应纳税额
    echo "This month you need pay tax is $need_pay_tax"
    #总的税后收入
    total_out_tax_salary=$(echo "scale=2;$totalsalary - $total_tax" | bc)
    #本月税后收入
    thismonth_out_tax_salary=$(echo "scale=2;$total_out_tax_salary - $passed_out_tax_salary" | bc)
    echo "This month you will get salary is $thismonth_out_tax_salary"
    #更新已纳税数据
    have_pay_tax=$(echo "scale=2;$have_pay_tax + $need_pay_tax"|bc)
    #更新过去的不含税收入
    passed_out_tax_salary="$total_out_tax_salary"
}
# tax 19896.61 0 2 31.13 6006.50

function read_id() {
    echo "请输入你的代号，唯一"
    read -rp "Please input your Unique id:" id
    echo "你是新人吗？试用期期间"
    read -rp "Are you freshman? yes or no : " fm_yesno
    
}
function read_wage_basic() {
    echo "基本工资"
    read -rp "Please input your basic wage:" wage_basic
    isnumber=$(is_number "$wage_basic")
    if [ "$isnumber" == 1 ] && [ "$(echo "$wage_basic > 0 " | bc)" == 1 ] && [ "$(echo "$wage_basic <= 300000 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        read_wage_basic
    fi
}
function read_wage_job() {
    echo "岗位工资"
    read -rp "Please input your job wage:" wage_job
    isnumber=$(is_number "$wage_job")
    if [ "$isnumber" == 1 ] && [ "$(echo "$wage_job > 0 " | bc)" == 1 ] && [ "$(echo "$wage_job <= 300000 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        read_wage_job
    fi
}
function read_bonus() {
    echo "标准奖金"
    read -rp "Please input your standard bonus:" bonus
    isnumber=$(is_number "$bonus")
    if [ "$isnumber" == 1 ] && [ "$(echo "$bonus > 0 " | bc)" == 1 ] && [ "$(echo "$bonus <= 300000 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        read_bonus
    fi
}
function read_single_bonus() {
    #单项奖金，除却标准绩效奖金之外的奖金
    echo "有额外的单项奖励吗？除却标准奖金之外需要纳税的那种奖金"
    read -rp "Please input your single bonus, default 0: " single_bonus
    if [ -z "$single_bonus" ]; then
        single_bonus=0
    fi
    isnumber=$(is_number "$single_bonus")
    if [ "$isnumber" == 1 ] && [ "$(echo "$single_bonus >= 0 " | bc)" == 1 ] && [ "$(echo "$single_bonus <= 300000 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        read_single_bonus
    fi
}
function read_other_income() {
    #单项奖金，除却标准绩效奖金之外的奖金
    echo "报销收入，不需要纳税的那种，比如加班餐费"
    read -rp "Please input the other income,E.g Reimbursement, default 0: " other_income
    if [ -z "$other_income" ]; then
        single_bonus=0
    fi
    isnumber=$(is_number "$other_income")
    if [ "$isnumber" == 1 ] && [ "$(echo "$other_income >= 0 " | bc)" == 1 ] && [ "$(echo "$other_income <= 300000 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        read_other_income
    fi
}
function read_score() {
    bonus=$1
    echo "绩效考核分数"
    read -rp "Please input your Assessment score:" score
    isnumber=$(is_number "$score")
    if [ "$isnumber" == 1 ] && [ "$(echo "$score > 0 " | bc)" == 1 ] && [ "$(echo "$score <= 200 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        read_score "$@"
    fi
    case "$fm_yesno" in
    yes|y|Y|YES)
       try_code=$(echo "scale=2;(($wage_basic+$wage_job+$bonus)*0.9-$wage_basic)/($wage_job+$bonus)" |bc)
       result_bonus=$(echo "scale=2;$bonus*$score*$try_code/100" | bc)
        ;;
    *)
       result_bonus=$(echo "scale=2;$bonus*$score/100" | bc)
        ;;
    esac

    
}

function getleaveday() {
    echo "有没有请事假？扣工资扣奖金的那种"
    read -rp "Please input this month, how many days you have asked for leave? default 0: " leave_day
    if [ -z "$leave_day" ]; then
        leave_day=0
    fi
    isnumber=$(is_number "$leave_day")
    if [ "$isnumber" == 1 ] && [ "$(echo "$leave_day >= 0 " | bc)" == 1 ] && [ "$(echo "$leave_day <= 20 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        getleaveday "$@"
    fi
}
function getovertime_workday() {
    echo "工作日加班小时数"
    read -rp "Please input this month, how many hours of overtime at workday,not weekend? default 0: " overtime_workday
    if [ -z "$overtime_workday" ]; then
        overtime_workday=0
    fi
    isnumber=$(is_number "$overtime_workday")
    if [ "$isnumber" == 1 ] && [ "$(echo "$overtime_workday >= 0 " | bc)" == 1 ] && [ "$(echo "$overtime_workday <= 100 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        getovertime_workday "$@"
    fi
}
function getovertime_holiday() {
    echo "法定假日加班小时数"
    read -rp "Please input this month, how many hours of overtime at holiday? default 0: " overtime_holiday
    if [ -z "$overtime_holiday" ]; then
        overtime_holiday=0
    fi
    isnumber=$(is_number "$overtime_holiday")
    if [ "$isnumber" == 1 ] && [ "$(echo "$overtime_holiday >= 0 " | bc)" == 1 ] && [ "$(echo "$overtime_holiday <= 100 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        getovertime_holiday "$@"
    fi
}
function calwage() {
    #计算工资,不含报销其他收入
    wage_basic=$1
    wage_job=$2
    work_day=$3
    leave_day=$4
    overtime_workday=$5
    overtime_holiday=$6

    wage=$((wage_basic + wage_job))
    wage_hour=$(echo "scale=2;$wage/21.75/8" | bc)
    #如果是新人，进行工资折算
    case "$fm_yesno" in
    yes|y|Y|YES)
        wage=$(echo "scale=2;$wage_basic + $wage_job*$try_code"|bc)
        wage_hour=$(echo "scale=2;$wage/21.75/8" | bc)
        workday_wage=$(echo "scale=2;$wage*(1-($calendar_work_day-$work_day)/21.75)-$leave_day*$wage_hour*8" | bc)
        overtime_wage=$(echo "scale=2;$overtime_workday*$wage_hour*1.5+$overtime_holiday*$wage_hour*3" | bc)
        ;;
    *)
        workday_wage=$(echo "scale=2;$wage-$leave_day*$wage_hour*8" | bc)
        overtime_wage=$(echo "scale=2;$overtime_workday*$wage_hour*1.5+$overtime_holiday*$wage_hour*3" | bc)
        ;;
    esac
    result_bonus=$(echo "scale=2;$result_bonus*(1+($work_day-$calendar_work_day)/21.75)"|bc)
    # echo "$result_wage"
}

function tax_ready() {
    workday_wage=$1
    overtime_wage=$2
    total_insurance_per=$3
    house_fund_per=$4
    result_bonus=$5
    single_bonus=$6
    passed_totalsalary=$7
    thismonth_totalsalary=$(echo "scale=2;$workday_wage+$overtime_wage-$total_insurance_per-$house_fund_per+$result_bonus+$single_bonus" | bc)
    totalsalary=$(echo "scale=2;$passed_totalsalary+$thismonth_totalsalary"|bc)
    echo "请参照个税APP，以填报数据为准。
1、子女教育，扣除标准为每子女每月1000元。填写信息包括子女受教育信息，含受教育阶段、受教育时间段等；子女、配偶身份证件号码。

2、继续教育，扣除标准为每月400元或3600元/年学历(学位)。继续教育信息包括，教育阶段、入学时间、毕业时间；职业资格继续教育信息包括：教育类型、证书取得时间、证书名称、证书编号、发证机关。

3、大病医疗，如果想要享受这项专项附加扣除，必须是纳税人扣除医保报销后，个人负担累计超过15000元的部分，并由纳税人在办理年度汇算清缴时，在80000元限额内据实扣除。填写时需提供患者信息和医疗信息。其中，患者信息包括本人及配偶、未成年子女发生的大病医疗费用支出可限额内据实扣除；医疗信息包括个人负担金额、医药费用金额等。

4、住房贷款利息，扣除标准为每月1000元，扣除期限最长可达20年。填写信息包括产权证明和贷款合同。其中，产权证明包含产权证、不动产登记证、商品房买卖合同和预售合同；贷款合同，按照贷款合同内容据实填写。

5、住房租金，扣除标准为800-1500元不等。填写信息包括住房租赁信息和工作城市信息。其中，住房租赁信息包括，获取合同编号，租赁房屋坐落地址，租赁方信息。

6、赡养老人，扣除标准为最高每月2000元。填写信息包括被赡养人信息和共同赡养人信息。被赡养人信息包括身份证件信息、出生日期，被赡养人需要年满60(含)周岁；共同赡养人信息包括身份证件信息、出生日期，如果是独生子女不需要填写。
"
    echo "请输入专项扣除合计金额/每月"
    read -rp "Please input Total special additional deductions monthly:" total_add_ded
    isnumber=$(is_number "$total_add_ded")
    if [ "$isnumber" == 1 ] && [ "$(echo "$total_add_ded >= 0 " | bc)" == 1 ] && [ "$(echo "$total_add_ded <= 10000 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        tax_ready "$@"
    fi
    echo "你在这家公司工作了几个月"
    read -rp "Please input How many months have you worked for this company: " worked_month
    isnumber=$(is_number "$worked_month")
    if [ "$isnumber" == 1 ] && [ "$(echo "$worked_month > 0 " | bc)" == 1 ] && [ "$(echo "$worked_month <= 12 " | bc)" == 1 ]; then
        :
    else
        echo "Please check your input."
        tax_ready "$@"
    fi

    # #工薪收入总额
    # totalsalary=$1
    # #专项附加扣除
    # total_add_ded=$2
    # base=5000
    # worked_month=$3
    # have_pay_tax=$4
    # passed_out_tax_salary=$5

}

function read_db_txt_file() {
    if ! [ -d ~/.salarycal ]; then
        mkdir ~/.salarycal
    fi
    if ! [ -f  ~/.salarycal/"$id""$stop_day_year".txt ]; then
        touch ~/.salarycal/"$id""$stop_day_year".txt
    else
        echo "Your id have exist,will use it: ~/.salarycal/${id}${stop_day_year}.txt"
    fi

    db_txt_file=~/.salarycal/"$id""$stop_day_year".txt
    if [[ $(head -n 1 "$db_txt_file" | awk '{print $1}') == "month" ]]; then
       :
    else
        echo "month     work_days   basic_wage       job_wage        bonus           score         result_bonus         single_bonus        other_income        insurance       insurance_corp         insurance_per             house_fund         house_fund_corp          house_fund_per             totalsalary           tax         total_tax         out_tax_salary         total_out_tax_salary       Paid_wages          Paid_bonus " | tee -a "$db_txt_file" &>/dev/null
        echo "年月       工作天数     基本工资          岗位工资          标准奖金         考核分           应得奖金              单项奖金            报销无需纳税金额       五险金额         公司缴纳五险部分          个人缴纳五险部分            住房公积金           公司缴纳公积金              个人缴纳公积金               应纳税所得额           个税        累计个税                税后收入                累计税后收入      实发工资            实发奖金    " | tee -a "$db_txt_file" &>/dev/null

    fi

    db_txt_file=~/.salarycal/"$id""$stop_day_year".txt

    if [[ $(head -n 1 "$db_txt_file" | awk '{print $1}') == 'month' ]]; then
    if awk '{print $1}' < "$db_txt_file" |grep -q "${stop_day_year}${stop_day_month}" ;then
        read -rp "The db file has existing "${stop_day_year}${stop_day_month}" data, delete that?: yes or no? " overrite_yn
        case "$overrite_yn" in
        no|NO|N|n)
            exit 1
            ;;
        *)
            sed -ri "/^${stop_day_year}${stop_day_month}/d" "$db_txt_file"
            ;;
        esac
    fi
   fi

    if [ -f "$db_txt_file" ]; then
    	db_txt_file_rows=$(cat "$db_txt_file"|wc -l)
        if [ "$db_txt_file_rows" ==  2 ];then
        	have_pay_tax=0
		    passed_out_tax_salary=0
            passed_totalsalary=0
	elif [ "$db_txt_file_rows" -gt  2 ];then
	    	have_pay_tax=$(tail -n 1 "$db_txt_file" | awk '{print $18}')
	    	passed_out_tax_salary=$(tail -n 1 "$db_txt_file" | awk '{print $20}')
            passed_totalsalary=$(tail -n 1 "$db_txt_file" | awk '{print $16}')
	
	   fi
    fi

}

function write_db_txt_file() {
    db_txt_file=~/.salarycal/"$id""$stop_day_year".txt
    if [[ $(head -n 1 "$db_txt_file" | awk '{print $1}') == 'month' ]]; then    	
        echo "${stop_day_year}${stop_day_month}       $work_day    $wage_basic     $wage_job   $bonus      $score      $result_bonus       $single_bonus       $other_income       $(echo "scale=2;$total_insurance_corp+$total_insurance_per"|bc)    $total_insurance_corp       $total_insurance_per        $(echo "scale=2;$house_fund_corp+$house_fund_per"|bc)   $house_fund_corp        $house_fund_per     $totalsalary        $need_pay_tax       $have_pay_tax       $thismonth_out_tax_salary       $passed_out_tax_salary      $(echo "scale=2;$thismonth_out_tax_salary+$other_income-$result_bonus-$single_bonus"|bc)        $(echo "$result_bonus+$single_bonus"|bc)    " | tee -a "$db_txt_file"
   fi
}

function print_result() {
    if [ -z "$id" ];then
        read_id
        echo "请输入工作年份"
        read -rp "Please input the work year: " stop_day_year
        if [ -z "$stop_day_year" ];then
            echo "Please check your input."
            print_result
        fi

        if date -d "$stop_day_year" +%Y > /dev/null 2>&1; then 
            :
        else
            echo "Please check your input."
            echo "输入的年份格式不正确，应为yyyy"
            print_result
        fi
    fi
	db_txt_file=~/.salarycal/"${id}${stop_day_year}".txt

    if [ -f "$db_txt_file" ];then
        :
    else
        echo "The "$db_txt_file" is not exist."
        exit 1
    fi

	for x in {1..22};do
		sed -n "1,1p" "$db_txt_file"|awk '{print $'$x'}' | tr "\n" ":  " && sed -n "2,1p" "$db_txt_file"|awk '{print $'$x'}' | tr "\n" ":  " && sed -n "$,1p" "$db_txt_file"|awk '{print " " $'$x'}'
	done                                                
}

# insurance "$life_base" "$life_rate_corp" "$life_rate_per" "$unemployment_base" "$unemployment_rate_corp" "$unemployment_rate_per" "$workinjury_base" "$workinjury_rate_corp" "$maternity_base" "$maternity_rate_corp" "$medical_base" "$medical_rate_corp" "$medical_rate_per" "$house_fund_base" "$house_fund_rate_corp" "$house_fund_rate_per"
# calwage 2500 8214 23 0 4.5 0

function main() {
    read_id
    read_wage_basic
    read_wage_job
    read_bonus
    read_score "$bonus"
    read_single_bonus
    read_other_income       
    read_workday_start_stop
    cal_workday "$start_day" "$stop_day" 
    read_db_txt_file 
    getleaveday
    getovertime_workday
    getovertime_holiday
    get_insurance_base "$wage_basic" "$wage_job" "$bonus"
    get_insurance_rate
    insurance "$life_base" "$life_rate_corp" "$life_rate_per" "$unemployment_base" "$unemployment_rate_corp" "$unemployment_rate_per" "$workinjury_base" "$workinjury_rate_corp" "$maternity_base" "$maternity_rate_corp" "$medical_base" "$medical_rate_corp" "$medical_rate_per" "$house_fund_base" "$house_fund_rate_corp" "$house_fund_rate_per"
    calwage "$wage_basic" "$wage_job" "$work_day" "$leave_day"  "$overtime_workday" "$overtime_holiday"
    tax_ready "$workday_wage" "$overtime_wage" "$total_insurance_per" "$house_fund_per" "$result_bonus" "$single_bonus" "$passed_totalsalary"
    tax "$totalsalary" "$total_add_ded" "$worked_month" "$have_pay_tax" "$passed_out_tax_salary"
    write_db_txt_file
    print_result
}

echo "
    Accounting is a science. 
    The calculation of wages and taxation involves many aspects, is complicated, 
    and is not easy to calculate manually, and generally requires a special information system to achieve.
    This script is just a simple tool for calculating salary.
    It does not involve sick leave, marriage leave, maternity leave, paternity leave, business trip, welfare and many other matters.
    It is mainly for writing SHELL scripts, and the calculation results are for entertainment only.
    Suggestions for improvement of the script itself are welcome.
    Do not complain about the accuracy of wages and calculations.

    会计是门科学，工资及税务计算涉及很多方面，
    具有复杂性，手工不易计算，一般需要专门的信息化系统实现。    
    这是个简单计算工资的脚本，不涉及病假、婚假、产假、陪产假、出差、福利等诸多事项。
    主要是为了写SHELL脚本，计算结果仅供娱乐。
    欢迎针对脚本本身提出改进意见。
    请勿吐槽工资本身及计算的准确性。

    v1.0 by sandylaw <freelxs@gmail.com>
"

if [ "$1" == 'print' ]; then
    print_result
else
    main
fi
