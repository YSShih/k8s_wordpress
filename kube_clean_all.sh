#!/bin/bash
kubectl delete service --all
kubectl delete deployment --all
kubectl delete pod --all
kubectl delete pv --all
kubectl delete pvc --all
kubectl delete secrets --all
kubectl delete configmaps --all
kubectl delete hpa --all
kubectl delete namespace --all
kubectl delete all --all