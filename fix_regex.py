with open("dartmini_ide/lib/services/compiler_service.dart", "r") as f:
    code = f.read()

code = code.replace(".replaceAll('^\"|\"\\$', '')", ".replaceAll(RegExp(r'^\"|\"$'), '')")

with open("dartmini_ide/lib/services/compiler_service.dart", "w") as f:
    f.write(code)
