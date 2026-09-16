#!/usr/bin/env python3
"""Generate a dependency-free Xcode project. Stable IDs keep diffs reviewable."""
import hashlib
import json
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
objects = {}
def ident(name): return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def obj(object_key, isa, **values):
    key = ident(object_key)
    objects[key] = dict(isa=isa, **values)
    return key
def ref(path, filetype):
    return obj('file:'+path, 'PBXFileReference', lastKnownFileType=filetype, path=path, sourceTree='<group>')
def build(target, reference, settings=None):
    return obj('build:'+target+':'+reference, 'PBXBuildFile', fileRef=reference, **({'settings':settings} if settings else {}))

config = ROOT/'Config'
config.mkdir(exist_ok=True)
host_info = dict(CFBundleDevelopmentRegion='en', CFBundleExecutable='$(EXECUTABLE_NAME)',
    CFBundleIdentifier='$(PRODUCT_BUNDLE_IDENTIFIER)', CFBundleName='gogo', CFBundleDisplayName='gogo',
    CFBundlePackageType='APPL', CFBundleShortVersionString='0.1.0', CFBundleVersion='1',
    CFBundleIconFile='AppIcon', LSMinimumSystemVersion='$(MACOSX_DEPLOYMENT_TARGET)',
    LSUIElement=True, NSHighResolutionCapable=True,
    CFBundleDocumentTypes=[dict(CFBundleTypeName='gogo Launch Request', CFBundleTypeRole='Viewer',
        LSHandlerRank='None', LSItemContentTypes=['cn.053x.gogo.launch-request'])],
    UTExportedTypeDeclarations=[dict(UTTypeIdentifier='cn.053x.gogo.launch-request',
        UTTypeConformsTo=['public.data'], UTTypeDescription='gogo Launch Request',
        UTTypeTagSpecification={'public.filename-extension':['gogorequest']})],
    NSDesktopFolderUsageDescription='gogo needs access to open items from your Desktop in the apps you choose.',
    NSDocumentsFolderUsageDescription='gogo needs access to open items from Documents in the apps you choose.',
    NSDownloadsFolderUsageDescription='gogo needs access to open items from Downloads in the apps you choose.',
    NSRemovableVolumesUsageDescription='gogo needs access to open items on external drives in the apps you choose.',
    NSNetworkVolumesUsageDescription='gogo needs access to open items on network volumes in the apps you choose.',
    NSAppleEventsUsageDescription='gogo needs permission to control iTerm2 to open a terminal in the folder you choose.')
extension_info = dict(CFBundleDevelopmentRegion='en', CFBundleExecutable='$(EXECUTABLE_NAME)',
    CFBundleIdentifier='$(PRODUCT_BUNDLE_IDENTIFIER)', CFBundleName='gogo Finder',
    CFBundleDisplayName='gogo', CFBundlePackageType='XPC!', CFBundleShortVersionString='0.1.0',
    CFBundleVersion='1', LSMinimumSystemVersion='$(MACOSX_DEPLOYMENT_TARGET)',
    NSExtension=dict(NSExtensionPointIdentifier='com.apple.FinderSync', NSExtensionPrincipalClass='$(PRODUCT_MODULE_NAME).FinderSync'))
for filename, value in [('Gogo-Info.plist',host_info),('Finder-Info.plist',extension_info),
    ('Gogo.entitlements', {'com.apple.security.automation.apple-events':True}),
    ('Finder.entitlements', {'com.apple.security.app-sandbox':True, 'com.apple.security.temporary-exception.shared-preference.read-only':['cn.053x.gogo.settings'], 'com.apple.security.temporary-exception.files.home-relative-path.read-write':['/Library/Application Support/cn.053x.gogo/']})]:
    (config/filename).write_bytes(plistlib.dumps(value,sort_keys=False))

files = []
shared = [*sorted(ROOT.glob('Sources/GogoCore/*.swift')), ROOT/'Sources/Platform.swift']
target_ids = {}
products = []
for name, directory, product, bundle, kind in [
    ('GogoFinder','GogoFinder','GogoFinder.appex','cn.053x.gogo.finder','com.apple.product-type.app-extension'),
    ('gogo','Gogo','gogo.app','cn.053x.gogo','com.apple.product-type.application')]:
    srcs=[]
    for path in [*shared,*sorted((ROOT/'Sources'/directory).glob('*.swift'))]:
        file=ref(str(path.relative_to(ROOT)), 'sourcecode.swift')
        if file not in files: files.append(file)
        srcs.append(build(name,file))
    sources = obj(name+':sources','PBXSourcesBuildPhase',buildActionMask=2147483647,files=srcs,runOnlyForDeploymentPostprocessing=0)
    resources=[]
    for path, ftype in [('Resources/AppIcon.icns','image.icns'),('Assets/AppIcon.png','image.png'),
                        ('Assets/GogoTemplate.svg','text.xml')]:
        file=ref(path,ftype)
        if file not in files: files.append(file)
        resources.append(build(name,file))
    for resource in ['Localizable.strings','InfoPlist.strings']:
        children=[]
        for lang in ['en','zh-Hans']:
            file=obj('localized:'+lang+':'+resource,'PBXFileReference',lastKnownFileType='text.plist.strings',name=lang,path=f'Resources/{lang}.lproj/{resource}',sourceTree='<group>')
            children.append(file)
        group=obj('localizations:'+resource,'PBXVariantGroup',children=children,name=resource,sourceTree='<group>')
        if group not in files: files.append(group)
        resources.append(build(name,group))
    resources=obj(name+':resources','PBXResourcesBuildPhase',buildActionMask=2147483647,files=resources,runOnlyForDeploymentPostprocessing=0)
    frameworks=obj(name+':frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)
    product_ref=obj(name+':product','PBXFileReference',explicitFileType='wrapper.app-extension' if name=='GogoFinder' else 'wrapper.application',path=product,sourceTree='BUILT_PRODUCTS_DIR',includeInIndex=0)
    products.append(product_ref)
    configs=[]
    for mode in ['Debug','Release']:
        settings=dict(PRODUCT_NAME=name, PRODUCT_BUNDLE_IDENTIFIER=bundle, SWIFT_VERSION='5.0',
            MACOSX_DEPLOYMENT_TARGET='15.7', SDKROOT='macosx', CODE_SIGN_STYLE='Automatic', CODE_SIGN_IDENTITY='-',
            CODE_SIGN_ENTITLEMENTS=f'Config/{"Finder" if name=="GogoFinder" else "Gogo"}.entitlements',
            INFOPLIST_FILE=f'Config/{"Finder" if name=="GogoFinder" else "Gogo"}-Info.plist',
            GENERATE_INFOPLIST_FILE='NO', ENABLE_HARDENED_RUNTIME='YES', ENABLE_DEBUG_DYLIB='NO',
            SWIFT_OPTIMIZATION_LEVEL='-Onone' if mode=='Debug' else '-O',
            DEBUG_INFORMATION_FORMAT='dwarf', CLANG_ENABLE_MODULES='YES',
            LD_RUNPATH_SEARCH_PATHS=['$(inherited)','@executable_path/../Frameworks'],
            COMBINE_HIDPI_IMAGES='YES')
        if name=='GogoFinder': settings.update(APPLICATION_EXTENSION_API_ONLY='YES', SKIP_INSTALL='YES')
        configs.append(obj(name+':'+mode,'XCBuildConfiguration',buildSettings=settings,name=mode))
    configs=obj(name+':configs','XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
    phases=[sources,frameworks,resources]
    dependencies=[]
    if name=='gogo':
        extension_product=ident('GogoFinder:product')
        embed=obj('gogo:embed','PBXCopyFilesBuildPhase',buildActionMask=2147483647,dstPath='',dstSubfolderSpec=13,
            files=[build('gogo-embed',extension_product,{'ATTRIBUTES':['RemoveHeadersOnCopy']})],name='Embed Finder Extension',runOnlyForDeploymentPostprocessing=0)
        phases.append(embed)
        proxy=obj('extension-proxy','PBXContainerItemProxy',containerPortal=ident('project'),proxyType=1,remoteGlobalIDString=target_ids['GogoFinder'],remoteInfo='GogoFinder')
        dependencies=[obj('extension-dependency','PBXTargetDependency',target=target_ids['GogoFinder'],targetProxy=proxy)]
    target_ids[name]=obj(name+':target','PBXNativeTarget',buildConfigurationList=configs,buildPhases=phases,buildRules=[],dependencies=dependencies,name=name,productName=name,productReference=product_ref,productType=kind)

product_group=obj('products','PBXGroup',children=products,name='Products',sourceTree='<group>')
main_group=obj('main-group','PBXGroup',children=files+[product_group],sourceTree='<group>')
configs=[obj('project:'+mode,'XCBuildConfiguration',buildSettings={'MACOSX_DEPLOYMENT_TARGET':'15.7','SDKROOT':'macosx'},name=mode) for mode in ['Debug','Release']]
project_configs=obj('project-configs','XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
project=obj('project','PBXProject',attributes={'LastUpgradeCheck':'2700','BuildIndependentTargetsInParallel':'YES'},buildConfigurationList=project_configs,compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','zh-Hans'],mainGroup=main_group,productRefGroup=product_group,projectDirPath='',projectRoot='',targets=[target_ids['gogo'],target_ids['GogoFinder']])

def serialize(value, level=0):
    if isinstance(value, dict): return '{\n'+''.join('\t'*(level+1)+json.dumps(k)+' = '+serialize(v,level+1)+';\n' for k,v in value.items())+'\t'*level+'}'
    if isinstance(value, list): return '('+', '.join(serialize(x,level) for x in value)+')'
    if isinstance(value, int): return str(value)
    return json.dumps(value)
path=ROOT/'gogo.xcodeproj'
path.mkdir(exist_ok=True)
(path/'project.pbxproj').write_text('// !$*UTF8*$!\n'+serialize(dict(archiveVersion=1,classes={},objectVersion=56,objects=objects,rootObject=project))+'\n')
scheme=path/'xcshareddata/xcschemes'
scheme.mkdir(parents=True,exist_ok=True)
(scheme/'gogo.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
   <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_ids['gogo']}" BuildableName="gogo.app" BlueprintName="gogo" ReferencedContainer="container:gogo.xcodeproj"/>
  </BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES">
  <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_ids['gogo']}" BuildableName="gogo.app" BlueprintName="gogo" ReferencedContainer="container:gogo.xcodeproj"/></BuildableProductRunnable>
 </LaunchAction>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated gogo.xcodeproj')
