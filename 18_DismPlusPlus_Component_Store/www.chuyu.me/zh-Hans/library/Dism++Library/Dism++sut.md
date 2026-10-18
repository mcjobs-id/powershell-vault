# 通用安装脚本——sut
通用安装脚本用于将软件整合到离线系统，并且整合是原生整合，而非通过应答实现。这意味着可以大大缩短系统安装时间。

[ [下载SutWizard 1.0.0.2](http://cdn.chuyu.me/SutWizard_1.0.0.2_7ba6e8933b4b8ab5c85d09d435a9f8585d2764e3.zip) ]


## 核心思想
    安装一个软件其实很大程度上可以理解为，释放文件然后在导入相关注册表。因此理论上我们只需要把这些动作捕获，得到一个差异集合。那么就可以转移到其他相似的系统中。
	sut通用安装脚本就是如此，第一阶段：释放相关文件，第二阶：段导入注册表以及其他行为。而保存为一个sut文件是为了方便以后再次使用。
	为了降低sut制作门槛，我还提供了一个工具SutWizard，用于自动化产生差异以及制作sut文件。有需要的人士可以自行下载。


## Sut一般制作流程

要进行此过程，你必须准备`SutWizard`以及你需要安装的应用程序。


### 启动SutWizard（快速模式）


选择快速模式，然后点击下一步。

![](../images/sut/SutStart.jpg)


等待快照完成。

![](../images/sut/Wait.jpg)


过一段时间后，你将看到提示。这时进入第二阶段，安装你的应用程序。

![](../images/sut/InstallApp.jpg)


### 安装应用程序
当程序提示说你可以安装应用后，双击你需要安装的应用程序。这里我们以VC 2008为例。操作过程中请勿关闭SutWizard！

手动双击你需要的应用程序，然后让他安装完成。

![](../images/sut/StartInstallApp.jpg)


### SutWizard产生差异数据

VC 2008安装完成后，点击完成。这时程序会显示正在产生差异。稍等片刻……

![](../images/sut/ScanDiffer.jpg)


差异产生完成，程序会把数据放在这个目录。

![](../images/sut/DifferDone.jpg)

### 优化差异数据
一般情况下有较多垃圾，建议你手动删除不必要的数据。
打开这个目录后，你会看到`AppData`目录以及`Data`目录。AppData用于存在程序文件部分，你可以手动删除一些意外引入的垃圾文件。

Data这是软件的注册表以及规则文件。同样的注册表也可能意外引入大量垃圾，建议手动删除后继续。

在来说说`Data\Data.xml`，它是规则文件。打开后你一般可以看到如下所示：

![](../images/sut/ViewData.jpg)

其中 `IsInstallable` 节点必须填写，注释中也说了这个节点用于判断此软件是否适用目标系统。由于这个sut是在Windows 10 15063 x64里面制作的，因此一般的我们可以这样写：

```xml
<IsInstallable>
	<Applicable>
		<!--IsInstallable节点 用于判断此软件是否适用目标系统。请在此节点内输入检测条件。（必选）-->
		<!--目标系统必须是amd64体系-->
		<Arch>9</Arch>
		<!--系统版本必须是10.0.15063-->
		<OSVersion>10.0.15063</OSVersion>
	</Applicable>
</IsInstallable>
```

简单的就这样了，接下来你可以打包为sut。


### 打包Sut

同样的，此过程我们需要SutWizard，不过选择第三项，然后点击继续。

![](../images/sut/StartMakerSut.jpg)


填写刚才的目录，以及输入Sut文件保存路径，点击完成。稍等片刻……知道提示完成。

![](../images/sut/MakingSut.jpg)


这时你就可以将`C:\MyFirst.sut` 应用于其他的Windows 10 15063 x64。如果你希望你的脚本拥有更加广泛的适用性。请自行编辑Data.xml，让你的Sut更加通用。




## sut结构说明
sut其实是一个esd文件，这点分微软的轻松传送很相似。为什么Dism++也选用esd文件呢？首先他体积小，其次esd能完整保存硬链接以及文件流。接下来看看sut布局：


\Data\Data.xml
<br>\……


其中`\Data\Data.xml`是必选文件，用于记录元数据。元数据记录了这是什么软件以及安装流程。另外Data目录还存放了一些注册表文件，可以配合Data.xml使用。

而其他目录则随意命名，用于保存程序文件部分。在AppData的ImageName属性添加引用即可。


