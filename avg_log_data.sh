#!/bin/bash

fqp=$0
exe=${fqp##*/}

logFile=$1
printAll=1
plot=0
header=0
if [[ -z $logFile ]]; then echo "USAGE: $exe log.lammps [plot(plotting format)] [header]"; exit 1; fi

if [[ "$2" == "plot" ]]; then plot=1; fi

if [[ "$3" == "header" ]]; then header=1; fi


if [[ ! -f "$logFile" ]]
then
	echo "ERROR: Cannot locate log file -> \"$logFile\""
	echo "...exiting..."
	exit 1
fi

natom=`grep -A 1 "reading atoms" $logFile | tail -1 | awk '{print $1}'`

if [[ -z $natom ]] 
then
	natom=`grep "Loop time of" $logFile | awk '{print $(NF-1)}'` 
fi

outArray+=($natom)
symbArray+=("Number of Atoms")
unitArray+=(" ")

check=`grep Loop  ${logFile}  | wc -l`
if [ $check -eq 0 ]
        then
        line=`wc -l  ${logFile}  | awk '{print $1}'`
else
        line=`grep -n Loop  ${logFile}  | sed -e "s/:/ /g" | awk '{print $1}'`
fi
line2=$[$line-1]
line1=$[$line-50]

thermoLine=`grep Step $logFile`
IFS=', ' read -r -a thermoArray <<< "$thermoLine"


for id in "${!thermoArray[@]}"
do
	var=${thermoArray[id]}
	#echo $var $id
	case $var in
	"Press")
		pid=$((id+1))
		P=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$pid '{printf "%7.4f", $c/10000}' | awk '{ total += $1; count++ } END { print total/count }'`
                outArray+=($P)
                symbArray+=("Pressure")
		unitArray+=("GPa")
	;;
	"Pxx")
		pid=$((id+1))
                Px=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$pid '{print $c/10000}' | awk '{ total += $1; count++ } END { print total/count }'`
                outArray+=($Px)
                symbArray+=("Pressue_xx")
                unitArray+=("GPa")
	;;
	"Pyy")
		pid=$((id+1))
                Py=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$pid '{print $c/10000}' | awk '{ total += $1; count++ } END { print total/count }'`
                outArray+=($Py)
                symbArray+=("Pressure_yy")
                unitArray+=("GPa")
	;;
	"Pzz")
		pid=$((id+1))
                Pz=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$pid '{print $c/10000}' | awk '{ total += $1; count++ } END { print total/count }'`
                outArray+=($Pz)
                symbArray+=("Pressure_zz")
                unitArray+=("GPa")
	;;
	"Volume") 
		vid=$((id+1))
		Vpa=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$vid '{print $c/'$natom'}' | awk '{ total += $1; count++ } END { print total/count }'`
		V=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$vid '{print $c}' | awk '{ total += $1; count++ } END { print total/count }'`
		outArray+=($Vpa)
                symbArray+=("Atomic Volume")
		unitArray+=("A^3/atom")
		outArray+=($V)
		symbArray+=("Total Volume")
		unitArray+=("A^3")
	;;
	"Density")
		did=$((id+1))
		D=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$did '{printf "%7.4f", $c}' | awk '{ total += $1; count++ } END { print total/count }'`
		outArray+=($D)
                symbArray+=("Sample Density")
		unitArray+=("g/cm^3")
	;;
	"Temp")
		tid=$((id+1))
		T=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$tid '{print $c}' | awk '{ total += $1; count++ } END { print total/count }'`
		outArray+=($T)
                symbArray+=("Temperature")
                unitArray+=("K")
	;;
        "TotEng")
                eid=$((id+1))
                E=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$eid '{print $c/'$natom'}' | awk '{ total += $1; count++ } END { print total/count }'`
		outArray+=($E)
                symbArray+=("Tot Energy")
                unitArray+=("eV/atom")
	;;
	"KinEng")
                kid=$((id+1))
                KE=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$kid '{print $c/'$natom'}' | awk '{ total += $1; count++ } END { print total/count }'`
                outArray+=($KE)
                symbArray+=("Kin Energy")
                unitArray+=("eV/atom")
        ;;
	"PotEng")
                peid=$((id+1))
                PE=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$peid '{print $c/'$natom'}' | awk '{ total += $1; count++ } END { print total/count }'`
                outArray+=($PE)
                symbArray+=("Pot Energy")
                unitArray+=("eV/atom")
        ;;
	"Enthalpy")
                hid=$((id+1))
                H=`awk NR==$line1,NR==$line2 $logFile | awk -v c=$hid '{print $c/'$natom'}' | awk '{ total += $1; count++ } END { print total/count }'`
                outArray+=($H)
                symbArray+=("Enthalpy")
                unitArray+=("eV/atom")
        ;;
	"Step")
		sid=$((id+1))
		steps=`awk NR==$line2 $logFile | awk -v c=$sid '{printf "%d",$c}'`
		outArray+=($steps)
                symbArray+=("MD Steps")
                unitArray+=(" ")
	;;
	"Time")
		tid=$((id+1))
		time=`awk NR==$line2 $logFile | awk -v c=$tid '{printf "%7.3f",$c}'`
		outArray+=($time)
                symbArray+=("Sim Time")
                unitArray+=("ps")
	;;

	esac
done

if [[ $header -eq 1 ]]
then
	for idx in "${!outArray[@]}"
	do
        	printf "%s(%s)  " "${symbArray[idx]}" "${unitArray[idx]}"
	done
	printf "\n"
	exit 1
fi

if [[ $plot -eq 1 ]]
then
	for idx in "${!outArray[@]}"
	do
		printf "%f " "${outArray[idx]}"
	done
	echo " "        
else
	echo "LAMMPS Simualtion recap"
	echo "-----------------------"
	if [[ $check -eq 1 ]]
	then
        	echo "Simulation	= DONE"
	else
        	echo "Simulation	= NOT DONE"
	fi
	for idx in "${!outArray[@]}"
	do
		printf "%s	= %7.3f %s" "${symbArray[idx]}" "${outArray[idx]}" "${unitArray[idx]}"
        	echo " "
	done
fi



